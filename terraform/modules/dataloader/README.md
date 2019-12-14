## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| app\_name | Name of elastic beanstalk application that already exists | string | `"dataloader"` | no |
| autoscale\_max | Choose the maximum instances to be used by load balancer | string | `"2"` | no |
| autoscale\_min | Choose the minimum instances to be used by load balancer | string | `"1"` | no |
| ca\_private\_key\_ssm\_param\_name | SSM param name for CA private key | string | n/a | yes |
| ca\_public\_cert\_ssm\_param\_name | SSM param name for CA public cert | string | n/a | yes |
| ec2\_instance\_type | The instance type used to run the application | string | `"t2.micro"` | no |
| elb\_http\_port | Port number for http listener on ELB | string | `"8080"` | no |
| elb\_https\_port | Port number for https listener on ELB | string | `"443"` | no |
| elb\_logs\_bucket\_id | Id of the S3 bucket to upload ELB access logs to | string | n/a | yes |
| elb\_ssl\_policy | Specify a security policy to apply to the listener. This option is only applicable to environments with an application load balancer. | string | `"ELBSecurityPolicy-TLS-1-2-Ext-2018-06"` | no |
| elb\_type | Choose load balancer type between classic, application or network | string | `"application"` | no |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| environment\_type | Choose environment type between SingleInstance or LoadBalanced | string | `"LoadBalanced"` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| healthcheck\_url | The path to which to send health check requests | string | `"/health"` | no |
| hybrid\_subnet\_cidr\_blocks | List of CIDR blocks that identify hybrid subnet. Generally 10.0.0.0/8 | list | `<list>` | no |
| is\_http\_enabled | Uses http listener if enabled. Default is false. | string | `"false"` | no |
| is\_https\_enabled | Uses https listener if enabled. Default is true | string | `"true"` | no |
| is\_hybrid |  | string | `"false"` | no |
| private\_subnet\_ids | IDs for the private subnets. Both EC2 and ELB will be hosted in private subnets. | list | n/a | yes |
| redshift\_egress\_security\_group\_id | Security group that allows outbound access to data subnets on RedShift port | string | n/a | yes |
| s3\_bucket\_id | Id of the S3 bucket used for temp storage | string | n/a | yes |
| solution\_stack\_name | Solution stack to base your environment off of. Example stacks can be found in the Amazon API documentation: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html | string | `"64bit Amazon Linux 2018.03 v2.9.2 running Java 8"` | no |
| vpc\_cidr\_block | VPC CIDR block | string | n/a | yes |
| vpc\_id | VPC id | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cname | Fully qualified DNS name for the environment. |
| dataloader\_egress\_sg\_id | Dataloader egress security group Id |
| env\_id | Elastic Beanstalk environment ID. |
| env\_name |  |
| iam\_profile\_arn | ARN of EC2 IAM profile |

