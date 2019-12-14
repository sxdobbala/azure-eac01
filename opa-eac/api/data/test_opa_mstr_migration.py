import argparse


def main():
    parser = argparse.ArgumentParser(description="Input for MSTR Environment Migration")
    parser.add_argument(
        "--mstr_project_name", type=str, help="MicroStrategy project name"
    )
    parser.add_argument("--mstr_username", type=str, help="Microstrategy Username")
    parser.add_argument("--mstr_password_key", type=str, help="Microstrategy Password")
    parser.add_argument(
        "--folder_name", type=str, help="Folder containing the release objects"
    )
    parser.add_argument(
        "--migration_file",
        type=str,
        help="File containing the list of objects migrated",
    )
    parser.add_argument(
        "--migration_strategy",
        type=str,
        choices=["full", "delta"],
        default="delta",
        help="Pass 'full' or 'delta' for the migration approach to follow",
    )
    parser.add_argument(
        "--release_name",
        type=str,
        help="Release name as expected in migration file for which packages are being migrated",
    )
    args = parser.parse_args()

    print(
        f"--mstr_project_name {args.mstr_project_name} --mstr_username {args.mstr_username} --mstr_password_key {args.mstr_password_key} --folder_name {args.folder_name} --migration_file {args.migration_file} --migration_strategy {args.migration_strategy} --release_name {args.release_name}"
    )


if __name__ == "__main__":
    main()
