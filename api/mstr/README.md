# Microstrategy Infrastructure Configuration Scripts

It consists of python scripts to automate configuration of several Microstartegy configs. The scripts coverage includes 
- Cleaning microstrategy projects of client specific configurations.
- Creating microstrategy project backup.
- Setting up microstrategy project for client on-boarding.
- Setting up Enterprise Manager configurations.
- Importing Microstrategy metadata.
- Running full/delta migration of Microstrategy objects/packages for a release.
- Performing post dataload Microstrategy operations.
- Microstrategy, Redshift and MySQL utilities.
- Updating ODBC file with redshift drivers.

## Getting started

All of the automation is done using python scripts and require python installation on your system. We prefer to use "python_invoker.sh" to create a virtualenv and install the modules mentioned in the "requirements.txt". The "python_invoker.sh" creates a virtual environment inside folder - "pythoninvoker_venv" and the modules installed are - 
 - boto3
 - pexpect
 - mstrio-py==10.11.1
 - requests
 - pymysql
 - pytest-shutil
 - configparser
 - psycopg2-binary
 - pyyaml

### Initial Configuration

Following steps need to be followed to run any script
- Fork the original repository - https://github.optum.com/opa/OPA-EAC
- Clone your forked repository to your local system
```shell
git clone <forked repo url>
```
- Setup upstream for your local repository in order to pull latest changes from the original OPA-EAC repository.
```shell
git remote add upstream https://github.optum.com/opa/OPA-EAC
```
- To regularly update your local repository with changes in OPA-EAC
```shell
git pull upstream preprod
```

## Script Functionalities

### clean_mstr_project.py - Cleaning microstrategy project of client specific configurations

This script will clean an MSTR project by deleting all unnecesary client folders, users, user groups, connection maps, DB connections, DB logins, ODBC file sections, user profiles, subscriptions and schedules as per requirement to use the project for backup.

#### Sample Configuration

```shell
sh clean_mstr_project_invoker.sh --exclude_client_ids "H000000" "H592196" "H704847" "H302436" --exclude_client_names "Ascension" "Blue Cross NC" "NYU" "Mock" "Lahey" --mstr_project_name "Performance Analytics" --mstr_username {mstr_username} --mstr_password_key {mstr_password_key} --delete_subscriptions --delete_schedules
```
The "exclude_client_ids" and "exclude_client_names" mentioned are for example purpose only. 

##### Argument - `exclude_client_ids`
Type: `String`
Number of values supported: `0..n`
Required: `False`

Case-sensitive client identifiers e.g. 'H123456'. Multiple client IDs are supported and can be specified like 'H000000' 'H592196' 'H704847' (space-separated values). It is used to identify the client(s) for which the configurations should not be deleted.

##### Argument - `exclude_client_names`
Type: `String`
Number of values supported: `0..n`
Required: `False`

Client name(s) which will be used to identify client report folders. Multiple client names are supported and can be specified like 'Ascension' 'Blue Cross NC' 'NYU's. It is used to identify which client folders should not be deleted.

##### Argument - `mstr_project_name`
Type: `String`
Number of values supported: `1`
Required: `True`

MicroStrategy project name on which the script needs to be executed.

##### Argument - `mstr_username`
Type: `String`
Number of values supported: `1`
Required: `True`

Microstrategy Username which has access to the project passed to the script.

##### Argument - `mstr_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for microstrategy password for the user passed to the script.

##### Flag - `delete_subscriptions`
Required: `False`

Deletes all subscriptions if "delete_subscriptions" flag is set or when no "exclude_client_ids"/"exclude_client_names" are passed else do nothing.

##### Flag - `delete_schedules`
Required: `False`

Deletes all schedules except the ones owned by "Administrator" if "delete_schedules" flag is set or when no "exclude_client_ids"/"exclude_client_names" are passed else do nothing.

### create_mstr_backup.py - Creating microstrategy project backup

This script helps in creating a backup of an Microstartegy environment using "mstrbak" tool.

#### Sample Configuration

```shell
sh python_invoker.sh create_mstr_backup.py --mstr_username "<mstr_user>" --mstr_password_key "<mstr_password_key>" --mysql_username "<mysql_user>" --mysql_password_key "<mysql_password_key>" --s3_bucket_name "<s3_bucket_path" --s3_key_name "<s3_key_name>"
```

##### Argument - `mstr_username`
Type: `String`
Number of values supported: `1`
Required: `True`

Microstrategy Username which has access to the project passed to the script.

##### Argument - `mstr_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for microstrategy password for the user passed to the script.

##### Argument - `mysql_username`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL Username which has access to the project passed to the script.

##### Argument - `mysql_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for MySQL password for the MySQL user passed to the script.

##### Argument - `s3_bucket_name`
Type: `String`
Number of values supported: `1`
Required: `True`

S3 bucket where the backup will be uploaded.

##### Argument - `s3_key_name`
Type: `String`
Number of values supported: `1`
Required: `True`

S3 key where the backup will be uploaded.

### create_new_client.py - Setting up microstrategy project for client on-boarding

This script helps in on-boarding a new client to the project. It creates client specific folders, password keys, cube builder password, add ODBC entry for client database, setup new DB login, DB connection and connection map for client user group, update DB instance, apply ACLs(Access Control List) and update client specific parameters in OPA master.

#### Sample Configuration

```shell
sh python_invoker.sh create_new_client.py --client_id {client_id} --client_name '{client_name}' --client_has_egr {client_has_egr} --client_reporting_db {client_reporting_db} --mstr_project_name 'Performance Analytics' --mstr_username {mstr_user} --mstr_password_key {mstr_password_key} --redshift_host {redshift_host} --redshift_port {redshift_port} --redshift_id {redshift_id} --redshift_username {redshift_username} --redshift_client_database {redshift_client_database} --redshift_client_username {redshift_client_username} --opa_master_lambda {OPA_master_lambda}
```

##### Argument - `client_id`
Type: `String`
Number of values supported: `1`
Required: `True`

Client identifier e.g. H123456 for the client we are on-boarding.

##### Argument - `client_name`
Type: `String`
Number of values supported: `1`
Required: `True`

Client name which will be used to create report folders

##### Argument - `client_has_egr`
choices: ["Y", "N"]
Number of values supported: `1`
Required: `True`

Pass 'Y' if the client has Employer Group reports(EGR) support.

##### Argument - `client_reporting_db`
Type: `String`
Number of values supported: `1`
Required: `True`

Client reporting database

##### Argument - `mstr_project_name`
Type: `String`
Number of values supported: `1`
Required: `True`

MicroStrategy project name on which the script needs to be executed.

##### Argument - `mstr_username`
Type: `String`
Number of values supported: `1`
Required: `True`

Microstrategy Username which has access to the project passed to the script.

##### Argument - `mstr_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for microstrategy password for the user passed to the script.

##### Argument - `redshift_host`
Type: `String`
Number of values supported: `1`
Required: `True`

Redshift hostname.

##### Argument - `redshift_port`
Type: `String`
Number of values supported: `1`
Required: `True`

Redshift Port.

##### Argument - `redshift_id`
Type: `String`
Number of values supported: `1`
Required: `True`

Redshift ID.

##### Argument - `redshift_username`
Type: `String`
Number of values supported: `1`
Required: `True`

Redshift Username.

##### Argument - `redshift_client_database`
Type: `String`
Number of values supported: `1`
Required: `True`

Client Database.

##### Argument - `redshift_client_username`
Type: `String`
Number of values supported: `1`
Required: `True`

Client Database User.

##### Argument - `opa_master_lambda`
Type: `String`
Number of values supported: `1`
Required: `True`

Specify the opa master lambda function name.

### em_config_project.py - Setting up Enterprise Manager configuration

This was a temporary script to configure Enterprise Manager. It configures statistics for "Enterprise Manager" project, "Performance Analytics" project, deletes existing data loads for Enterprise Manager, creates a new data laod and starts monitoring for Enterprise Manager.

#### Sample Configuration

```shell
sh python_invoker.sh em_config_project.py --mstr_project_name "Performance Analytics" --mysql_host {mysql_host} --mysql_port {mysql_port} --mysql_username {mysql_username} --mysql_password_key {mysql_password_key} --mstr_username {mstr_user} --mstr_password_key {mstr_password_key}
```

##### Argument - `mstr_project_name`
Type: `String`
Number of values supported: `1`
Required: `True`

MicroStrategy project name on which the script needs to be executed.

##### Argument - `mysql_host`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL host

##### Argument - `mysql_port`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL port.

##### Argument - `mysql_username`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL Username which has access to the project passed to the script.

##### Argument - `mysql_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for MySQL password for the MySQL user passed to the script.

##### Argument - `mstr_username`
Type: `String`
Number of values supported: `1`
Required: `True`

Microstrategy Username which has access to the project passed to the script.

##### Argument - `mstr_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for microstrategy password for the user passed to the script.

### em_create_project.py - Creating an Enterprise Manager project and setting up its configuration

The script creates Enterprise Manager repository(creates a new MySQL DB if not already exists and updates the statistics ODBC entry), creates an Enterprise Manager project (overrides if already existing) and configures statistics for the "Enterprise Manager" project, "Performance Analytics" project, deletes existing data loads for Enterprise Manager, creates a new data load and starts monitoring for Enterprise Manager.

#### Sample Configuration

```shell
sh python_invoker.sh em_create_project.py --mstr_project_name "Performance Analytics" --mysql_host {mysql_host} --mysql_port {mysql_port} --mysql_stats_database {mysql_stats_database} --mysql_username {mysql_username} --mysql_password_key {mysql_password_key} --mstr_username {mstr_user} --mstr_password_key {mstr_password_key}
```

##### Argument - `mstr_project_name`
Type: `String`
Number of values supported: `1`
Required: `True`

MicroStrategy project name on which the script needs to be executed.

##### Argument - `mysql_host`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL host

##### Argument - `mysql_port`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL port.

##### Argument - `mysql_stats_database`
Type: `String`
Number of values supported: `1`
Required: `True`

AWS Mysql Statistics Database.

##### Argument - `mysql_username`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL Username which has access to the project passed to the script.

##### Argument - `mysql_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for MySQL password for the MySQL user passed to the script.

##### Argument - `mstr_username`
Type: `String`
Number of values supported: `1`
Required: `True`

Microstrategy Username which has access to the project passed to the script.

##### Argument - `mstr_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for microstrategy password for the user passed to the script.

### import_mstr_metadata.py - Importing Microstrategy metadata

The script syncs/downloads metadata from S3 to EC2, restores on-prem metadata DB to a new DB on MySQL, updates metadata ODBC entry to point to the new DB, registers OPA project on iServer, creates AWS MSTR admin account if not exists, updates OPA project configurations using the "project_config.json" in the current repo. folder. It also reverts ODBC settings to previous DB in case of script failure.

#### Sample Configuration

```shell
sh python_invoker.sh import_mstr_metadata.py --mstr_project_name "Performance Analytics" --mysql_host {mysql_host} --mysql_port {mysql_port} --mysql_metadata_database {mysql_metadata_database} --mysql_username {mysql_username} --mysql_password_key {mysql_password_key} --mstr_username {mstr_user} --mstr_password_key {mstr_password_key} --opa_username {opa_username} --opa_password_key {opa_password_key} --metadata_s3_uri {metadata_s3_uri}
```

##### Argument - `mstr_project_name`
Type: `String`
Number of values supported: `1`
Required: `True`

MicroStrategy project name on which the script needs to be executed.

##### Argument - `mysql_host`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL host

##### Argument - `mysql_port`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL port.

##### Argument - `mysql_metadata_database`
Type: `String`
Number of values supported: `1`
Required: `True`

AWS Mysql metadata Database.

##### Argument - `mysql_username`
Type: `String`
Number of values supported: `1`
Required: `True`

MySQL Username which has access to the project passed to the script.

##### Argument - `mysql_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for MySQL password for the MySQL user passed to the script.

##### Argument - `mstr_username`
Type: `String`
Number of values supported: `1`
Required: `True`

Microstrategy Username which has access to the project passed to the script.

##### Argument - `mstr_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for microstrategy password for the user passed to the script.

##### Argument - `opa_username`
Type: `String`
Number of values supported: `1`
Required: `True`

OPA master username which was used for the backup of the project.

##### Argument - `opa_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for microstrategy password for the user passed to the script.

##### Argument - `metadata_s3_uri`
Type: `String`
Number of values supported: `1`
Required: `True`

Metadata SQL dump file path.

### migrate_mstr_objects.py - Helps with full/delta migration of microstrategy packages for a release

This script will migrate MSTR objects to the local iserver project. The script assumes that the release components are already copied to the EC2 instance. The path for the parent folder of release folders in EC2 instance will be passed as an input to the script (Ex: /opt/opa/install/mstr-content). The migration strategy can specified to be "delta" or "full" based on the requirement. Delta migration uses the "migration_file.yaml" to figure out the packages which are already migrated for a release and migrate only the rest if required.

#### Sample Configuration

```shell
sh python_invoker.sh migrate_mstr_objects.py --mstr_project_name "Performance Analytics" --mstr_username {mstr_username} --mstr_password_key {mstr_password_key} --migration_base_folder "/opt/opa/install/mstr-content" --migration_strategy "delta" --migration_file {migration file path}
```

##### Argument - `mstr_project_name`
Type: `String`
Number of values supported: `1`
Required: `True`

MicroStrategy project name on which the script needs to be executed.

##### Argument - `mstr_username`
Type: `String`Number of values supported: `1`
Required: `True`

Microstrategy Username which has access to the project passed to the script.

##### Argument - `mstr_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for microstrategy password for the user passed to the script.

##### Argument - `migration_base_folder`
Type: `String`
Number of values supported: `1`
Required: `True`

Parent folder containing the release folders.

##### Argument - `migration_file`
Type: `String`
Number of values supported: `1`
Required: `False`

File containing the list of objects(packages or scripts) migrated release-wise specific to the environment/project. The default path used if this argument is not passed is - "{migration_base_folder passed to the script}/migration_file.yaml"

##### Argument - `migration_strategy`
choices: `["full", "delta"]`
Number of values supported: `1`
Required: `True`

Pass 'full' or 'delta' for the migration approach to follow while migrating packages for a release.

### post_data_load.py - Helps with full/delta migration of microstrategy packages for a release

The script purges MSTR element caches in all servers in the cluster, invalidate reeport caches in all servers in the cluster (History List isn't affected by this purge), publish cubes for the client if they support and only if it's a "monthly" data load and trigger client subscriptions.

#### Sample Configuration

```shell
sh python_invoker.sh post_data_load.py --mstr_username {mstr_username --mstr_password_key {mstr_password_key} --cube_builder_username {cube_builder_username} --cube_builder_password_key {cube_builder_password_key} --mstr_project_name "Performance Analytics" --client_id {client_id} --client_has_cubes {client_has_cubes} --dataload_type {dataload_type}
```

##### Argument - `mstr_username`
Type: `String`
Number of values supported: `1`
Required: `True`

Microstrategy Username which has access to the project passed to the script.

##### Argument - `mstr_password_key`
Type: `String`
Number of values supported: `1`
Required: `True`

SSM store location/key for microstrategy password for the user passed to the script.

##### Argument - `cube_builder_username`
Type: `String`
Number of values supported: `1`
Required: `False`

Microstrategy cube builder username which has access to the project passed to the script.

##### Argument - `cube_builder_password_key`
Type: `String`
Number of values supported: `1`
Required: `False`

SSM store location/key for microstrategy password for the cube builder user passed to the script.

##### Argument - `mstr_project_name`
Type: `String`
Number of values supported: `1`
Required: `True`

MicroStrategy project name on which the script needs to be executed.

##### Argument - `client_id`
Type: `String`
Number of values supported: `1`
Required: `True`

MSTR user group name for the Client e.g. H123456 should match with "client_id" passed.

##### Argument - `client_has_cubes`
Type: `String`
choices: `["Y", "N"]`
Number of values supported: `1`
Required: `True`

This flag specifies if the cubes have to be published for the client.

##### Argument - `dataload_type`
Type: `String`
choices: `["monthly", "daily"]`
Number of values supported: `1`
Required: `True`

This flag specifies data load type for the client.


## Contributing

If you'd like to contribute, please fork the repository and use a feature
branch. Pull requests are warmly welcome.

Following steps need to be followed to run or contribute to any script
- Fork the original repository - https://github.optum.com/opa/OPA-EAC
- Clone your forked repository to your local system
```shell
git clone <forked repo url>
```
- Setup upstream for your local repository in order to pull latest changes from the original OPA-EAC repository.
```shell
git remote add upstream https://github.optum.com/opa/OPA-EAC
```
- To regularly update your local repository with changes in OPA-EAC
```shell
git pull upstream preprod
```
- To create a branch in your local forked repo.
```shell
git checkout -b [name_of_your_new_branch]
```
- To push your new branch to GitHub.
```shell
git push origin [name_of_your_new_branch]
```
