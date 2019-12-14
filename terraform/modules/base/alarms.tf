# data "aws_instances" "ec2-instances-list" {
#   instance_tags = {
#     Environment = "${var.env_prefix}"
#   }
# }
# data "aws_lb" "default" {
#   name = "${var.env_prefix}-appelb"
#   # TODO: we need a dependency but adding this throws "value of count cannot be computed"
#   #depends_on = ["module.opa-app-elb"]
# }
# module "rds_instances" {
#   source        = "../filter-instances-by-tag"
#   resource_type = "rds"
#   tag_filters   = "{'${var.tag_prefix}:environment':'${var.env_prefix}'}"
# }
# module "redshift_instances" {
#   source        = "../filter-instances-by-tag"
#   resource_type = "redshift"
#   tag_filters   = "{'${var.tag_prefix}:environment':'${var.env_prefix}'}"
# }
# module "alarms" {
#   source                      = "../../modules/cloudwatch-alerts"
#   env_prefix                  = "${var.env_prefix}"
#   alarms_email                = "${var.alarms_email}"
#   thresholds                  = "${var.alarm_thresholds}"
#   ec2_instanceIds             = ["${data.aws_instances.ec2-instances-list.ids}"]
#   load_balancers              = ["${data.aws_lb.default.arn_suffix}"]
#   rds_instanceIds             = ["${module.rds_instances.filtered_instances}"]
#   redshift_clusterIdentifiers = ["${module.redshift_instances.filtered_instances}"]
# }

