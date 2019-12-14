data "external" "filter_instances_by_tag" {
  program     = ["sh", "${path.module}/deploy.sh"]
  working_dir = "${path.module}"

  query = {
    resource_type = "${var.resource_type}"

    # query only accepts string type parameter
    tag_filters = "${var.tag_filters}"
  }
}
