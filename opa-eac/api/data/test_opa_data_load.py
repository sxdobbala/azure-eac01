import argparse


def main():
    parser = argparse.ArgumentParser(
        description="Creates l2-l5 entities, load data into staging schema & swap with rep schema"
    )

    parser.add_argument("--host_name", type=str, help="redshift instance host name")
    parser.add_argument(
        "--db_name", type=str, help="database name in which data needs to be loaded"
    )
    parser.add_argument(
        "--port", type=int, help="port in which database needs to be connected"
    )
    parser.add_argument("--user_name", type=str, help="user name to connect redshift")
    parser.add_argument(
        "--bucket",
        type=str,
        help="s3 bucket name in which the parquet files are uploaded",
    )
    parser.add_argument(
        "--file_prefix", type=str, help="Expected prefix for the parquet files"
    )
    parser.add_argument(
        "--iam_role", type=str, help="iam_role to execute copy commands"
    )
    parser.add_argument("--ddl_base_path", type=str, help="Base path for ddl files")
    parser.add_argument(
        "--dataload_type", type=str, help="monthly dataload or daily dataload"
    )

    args = parser.parse_args()
    print(
        f"--host_name {args.host_name} --db_name {args.db_name} --port {args.port} --user_name {args.user_name} --bucket {args.bucket} --file_prefix {args.file_prefix} --iam_role {args.iam_role} --ddl_base_path {args.ddl_base_path} --dataload_type {args.dataload_type}"
    )


if __name__ == "__main__":
    main()
