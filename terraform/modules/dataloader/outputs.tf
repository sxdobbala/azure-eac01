output "env_name" {
  value = "${aws_elastic_beanstalk_environment.dataloader_eb_env.name}"
}

output "env_id" {
  description = "Elastic Beanstalk environment ID."
  value       = "${aws_elastic_beanstalk_environment.dataloader_eb_env.id}"
}

output "cname" {
  description = "Fully qualified DNS name for the environment."
  value       = "${aws_elastic_beanstalk_environment.dataloader_eb_env.cname}"
}

output "iam_profile_arn" {
  description = "ARN of EC2 IAM profile"
  value       = "${aws_iam_instance_profile.dataloader_ec2_iam_profile.arn}"
}

output "dataloader_egress_sg_id" {
  description = "Dataloader egress security group Id"
  value = "${aws_security_group.dataloader_egress_sg.id}"
}