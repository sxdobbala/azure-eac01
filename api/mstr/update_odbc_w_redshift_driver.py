import argparse
import subprocess
import sys
import json
import datetime
import os
import configparser
import errno
from configparser import SafeConfigParser
from shutil import copyfile
from os import path


def add_section(odbc_file, client_odbc_entry, odbc_desc, template_file, client_details):
    """ Add new odbc entry for the client """
    parser = SafeConfigParser(strict=False)
    parser.optionxform = str

    if path.exists(template_file):
        parser.read(odbc_file)
        parser.set("ODBC Data Sources", client_odbc_entry, odbc_desc)
        with open(odbc_file, "w") as configfile:
            parser.write(configfile, space_around_delimiters=False)
        sed_params = f'cat {template_file} | sed -e "s,client_odbc_entry,{client_odbc_entry}," -e "s,redshift_client_database,{client_details["redshift_client_database"]},"  -e "s,redshift_host,{client_details["redshift_host"]},"  -e "s,redshift_client_username,{client_details["redshift_client_username"]}," >> {odbc_file}'
        sed_output = subprocess.check_output(sed_params, shell=True).decode("utf-8")
        print("Configured client odbc entry: " + client_odbc_entry)
    else:
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), template_file)


def delete_section(odbc_file, odbc_entry):
    """ Delete old odbc entry for the client """
    parser = SafeConfigParser(strict=False)
    parser.optionxform = str
    parser.read(odbc_file)

    parser.remove_section(odbc_entry)

    with open(odbc_file, "w") as configfile:
        parser.write(configfile, space_around_delimiters=False)


def get_section_details(odbc_file, odbc_entry):
    """ Get client specific odbc options """
    parser = SafeConfigParser(strict=False)
    parser.optionxform = str
    parser.read(odbc_file)
    client_details = {}
    client_details["redshift_host"] = parser.get(odbc_entry, "HostName")
    client_details["redshift_client_database"] = parser.get(odbc_entry, "Database")
    client_details["redshift_client_username"] = parser.get(odbc_entry, "LogonID")
    return client_details


def backup_odbc_file(src, dst=None):
    """ Backup and Return filename """
    if dst is None:
        filename = os.path.splitext(src)[0]
        extension = os.path.splitext(src)[1]
        dst = filename + "_bak_" + "{:%Y%m%d%H%M%S}".format(datetime.datetime.now())+extension
    copyfile(src, dst)
    return dst


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Replace odbc entry with redshift driver"
    )
    parser.add_argument(
        "--client_id", help="Client identifier e.g. H123456", required="true"
    )
    args = parser.parse_args()

    # Getting configs
    with open(os.path.join(sys.path[0], "general_config.json"), "r") as f:
        general_config = json.load(f)

    with open(os.path.join(sys.path[0], "project_config.json"), "r") as f:
        project_config = json.load(f)

    odbc_entry = project_config["client_odbc_entry"] + args.client_id

    redshift_odbc_template_file = os.path.join(
        sys.path[0], project_config["template_file"]
    )

    odbc_desc = general_config["redshift_odbc_desc"]

    odbc_file = general_config["odbc_file"]

    try:
        client_details = get_section_details(odbc_file, odbc_entry)

        backup_file_name = backup_odbc_file(odbc_file)

        delete_section(odbc_file, odbc_entry)

        add_section(
            odbc_file,
            odbc_entry,
            odbc_desc,
            redshift_odbc_template_file,
            client_details,
        )

    except configparser.NoSectionError as nse:
        print(str(nse))

    except FileNotFoundError as fe:
        print(str(fe))

    except Exception as e:
        print("Script Excecution failed due to " + str(e))

        #Reverting the changes from backup file
        print("Reverting the odbc file changes from the backup")
        backup_odbc_file(backup_file_name, odbc_file)
