import argparse


def main():
    parser = argparse.ArgumentParser(
        description="Create a new client user group and folders"
    )
    parser.add_argument(
        "--client_id", help="Client identifier e.g. H123456", required="true"
    )
    parser.add_argument(
        "--client_name",
        required="true",
        help="Client name which will be used to create report folders",
    )
    parser.add_argument(
        "--client_has_egr",
        required="true",
        help="Pass 'Y' if the client has Employer Group reports(EGR) support",
    )
    parser.add_argument(
        "--client_reporting_db", help="Client Reporting Database", required="true"
    )
    parser.add_argument(
        "--mstr_project_name", type=str, help="MicroStrategy project name"
    )
    parser.add_argument(
        "--mstr_username", help="MicroStrategy UserName", required="true"
    )
    parser.add_argument(
        "--mstr_password_key", help="MicroStrategy Password", required="true"
    )
    parser.add_argument("--redshift_host", help="Redshift Hostname", required="true")
    parser.add_argument("--redshift_port", help="Redshift Port", required="true")
    parser.add_argument("--redshift_id", help="Redshift ID", required="true")
    parser.add_argument(
        "--redshift_username", help="Redshift Username", required="true"
    )
    parser.add_argument(
        "--redshift_client_database", help="Client Database", required="true"
    )
    parser.add_argument(
        "--redshift_client_username", help="Client Database User", required="true"
    )
    parser.add_argument(
        "--opa_master_lambda",
        help="Specify the opa master lambda function name",
        required="true",
    )
    args = parser.parse_args()

    print(f"--client_id {args.client_id}")
    print(f"--client_name {args.client_name}")
    print(f"--client_has_egr {args.client_has_egr}")
    print(f"--client_reporting_db {args.client_reporting_db}")
    print(f"--mstr_project_name {args.mstr_project_name}")
    print(f"--mstr_username {args.mstr_username}")
    print(f"--mstr_password_key {args.mstr_password_key}")
    print(f"--redshift_host {args.redshift_host}")
    print(f"--redshift_port {args.redshift_port}")
    print(f"--redshift_id {args.redshift_id}")
    print(f"--redshift_username {args.redshift_username}")
    print(f"--redshift_client_database {args.redshift_client_database}")
    print(f"--redshift_client_username {args.redshift_client_username}")
    print(f"--opa_master_lambda {args.opa_master_lambda}")


if __name__ == "__main__":
    main()
