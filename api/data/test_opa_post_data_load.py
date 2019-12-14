import argparse


def main():
    parser = argparse.ArgumentParser(description="Execute post data load scripts")
    parser.add_argument(
        "--client_id", help="Client identifier e.g. H123456", required="true"
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
    parser.add_argument(
        "--client_has_cubes",
        type=str,
        choices=["Y", "N"],
        help="This flag specifies if the cubes have to be published for the client",
    )
    parser.add_argument(
        "--cube_builder_username", help="Cube builder username", required="true"
    )
    parser.add_argument(
        "--cube_builder_password_key",
        type=str,
        help="Cube builder password key",
        required="true",
    )
    parser.add_argument(
        "--dataload_type",
        type=str,
        choices=["monthly", "daily"],
        help="This flag specifies data load type for the client",
        required="true",
    )

    args = parser.parse_args()
    print(
        f"--client_id {args.client_id} --mstr_project_name {args.mstr_project_name} --mstr_username {args.mstr_username} --mstr_password_key {args.mstr_password_key} --client_has_cubes {args.client_has_cubes} --cube_builder_username {args.cube_builder_username} --cube_builder_password_key {args.cube_builder_password_key} --dataload_type {args.dataload_type}"
    )


if __name__ == "__main__":
    main()
