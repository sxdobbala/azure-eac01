# CloudWatch Metric Alarms

###Features:
- Adds below listed Cloudwatch Alerts:
    - EC2:
        - Cpu Utilization
        - Status Health Check
    - ApplicationELB:
        - Rejected Connection Count
        - Unhealthy Host Count
    - Redshift:
        - Cpu Utilization
        - Percentage Disk Space Used
    - RDS:
        - Burst Balance
        - Cpu Utilization
- Allows setting up threshold with respect to environemnts.
- Able to set alarms for a list of ec2-instances, elbs, Redshift clusters and RDS instances.
- Note: In order for this module to work all the ec2, rds, redshift instance should have an environment tag.

## Example Usage:
```hcl
locals {
  dev_thresholds = {
    ec2 = {
      cpu_utilization = "90"
    }
    load_balancer = {
      rejected_connection_count = "0"
      unhealthy_host_count = "0"
    }
    redshift = {
      cpu_utilization = "90"
      percentage_diskSpace_used = "80"
    }
    rds = {
      burst_balance   = "40"
      cpu_utilization = "90"
    }
  }
}

#Filters the list of instance with tag as dev/QA/Stage/Prod
data "aws_instances" "ec2-instances-list" {
  instance_tags = {
    Environment = "dev"
  }
}

data "aws_lb" "dev-lb" {
  name = "dev-appelb"
}


data "external" "filterRDSByTag" {
  program = ["python", "${path.module}/filterbytag.py"]
  query = {
    resourceType = "rds"
    tagKey = "Environment"
    tagValue = "dev"
  }
}

data "external" "filterRedshiftByTag" {
  program = ["python", "${path.module}/filterbytag.py"]
  query = {
    resourceType = "redshift"
    tagKey = "Environment"
    tagValue = "dev"
  }
}

module "dev-alarms" {
  source                      = "../../modules/cloudwatch-alerts"
  env_prefix                  = "${var.env_prefix}"
  alarms_email                = "${var.alarms_email}}"
  ec2_instanceIds             = ["${data.aws_instances.ec2-instances-list.ids}"]
  load_balancers              = ["${data.aws_lb.dev-lb.arn_suffix}"]
  redshift_clusterIdentifiers = ["${split(",",data.external.filterRedshiftByTag.result.dev)}"]
  rds_instanceIds             = ["${split(",",data.external.filterRDSByTag.result.dev)}"]
  thresholds                  = "${local.dev_thresholds}"
}
```
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alarms\_email |  | string | n/a | yes |
| ec2\_instanceIds |  | list | n/a | yes |
| env\_prefix | AWS environment you are deploying to. Will be appended to SNS topic and alarm name. (e.g. dev, stage, prod) | string | n/a | yes |
| load\_balancers |  | list | n/a | yes |
| opa\_api\_source\_code\_s3\_bucket | S3 bucket with API lambda source code | string | n/a | yes |
| opa\_api\_source\_code\_s3\_key | S3 key with API lambda source code | string | n/a | yes |
| rds\_instanceIds |  | list | n/a | yes |
| redshift\_clusterIdentifiers |  | list | n/a | yes |
| thresholds |  | map | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| sns\_topic\_arn | The ARN of the SNS topic |

