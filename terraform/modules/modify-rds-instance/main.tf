locals {
  rds_instances = ["${module.filtered_instances_by_tag.filtered_instances}"]

  # we don't want resizing to happen on stage/prod resources so set multiplier to zero
  prod_multiplier = "${var.is_prod == "true" ? 0 : 1}"
}

module "filtered_instances_by_tag" {
  source        = "../filter-instances-by-tag"
  resource_type = "rds"
  tag_filters   = "${var.tag_filters}"
}

resource "null_resource" "rds_instance_resizer" {
  count = "${length(local.rds_instances) * local.prod_multiplier}"

  triggers = {
    command_trigger = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "aws rds modify-db-instance --db-instance-identifier ${local.rds_instances[count.index]} --db-instance-class ${var.rds_instance_class} --apply-immediately"
  }

  # Change it to single-az as default. Need to configurable it if necessary.
  provisioner "local-exec" {
    command = "aws rds modify-db-instance --db-instance-identifier ${local.rds_instances[count.index]} --no-multi-az --apply-immediately"
  }
}
