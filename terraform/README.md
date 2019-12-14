# Terraform

## File System

```folder
terraform
│   README.md
|   oid-infra.groovy
└───src
│   │   level-0.tf
│   │   level-1.tf
|   |   level-2.tf
|   |   variables.tf
|   |   version.tf
│   └───other
│       │   ...
│       └───code_deploy
|           ...
└───dev
|   │   dev-state.tf
|   │   terraform.tfvars
|   |   ecr_lifecycle_policy.json
|   |   repos.tf
└───test
|   │   test-state.tf
|   │   terraform.tfvars
└───nonprod
|   │   ca-policy-attachment.tf
|   │   nonprod-state.tf
|   │   terraform.tfvars
└───stage
|   │   stage-state.tf
|   │   terraform.tfvars
└───prod
|   │   ca-policy-attachment.tf
|   │   prod-state.tf
|   │   terraform.tfvars
└───workspace
|   │   ...
```

Note that repos.tf contains the ECR and Code Commit requirements and these are only needed in the dev environment. The ecr_lifecycle_policy.json file contains the lifecycle policies needed for ECR repositories.

## Inputs

| Name                | Description                                              | Type   |
| ------------------- | -------------------------------------------------------- | :----: |
| aws_region          | aws region to create resources                           | string |
| aws_profile         | aws credential profile                                   | string |
| global_tags         | Addtioanl global tags to be applied to created resources | map    |
| tag_name_identifier | tag name identifier for the aws_base                     | string |

### CloudWatch

| Name                                     | Description                                                                                 | Type   |
| ---------------------------------------- | ------------------------------------------------------------------------------------------- | :----: |
| cw_ossec_destination_arn                 | ossec cloudwatch log destination arn to subscribe to                                        | string |
| cw_ossec_log_group_name                  | cloudwatch log group name for ossec                                                         | string |
| cw_ossec_log_group_retention_in_days     | number of days ossec log events will be retained in the log group                           | string |
| cw_ossec_subscription_filter_pattern     | filter pattern for ossec cloudwatch logs for subscribing to a filtered stream of log events | string |
| cw_ossec_with_cw_log_subscription_filter | whether to use subscription filter with ossec cloudwatch log group or not                   | string |

### Inspector

| Name                               | Description                            | Type   |
| ---------------------------------- | -------------------------------------- | :----: |
| inspector_assessment_run_duration  | Duration in seconds to run the scans   | string |
| inspector_assessment_target_name   | Inspector assessment target name       | string |
| inspector_assessment_template_name | Inspector assessment template name     | string |
| inspector_schedule_expression      | cron expression for inspector schedule | string |

### AWS Config

| Name                                                 | Description                                                                      | Type   |
| ---------------------------------------------------- | -------------------------------------------------------------------------------- | :----: |
| terraform_compliance_rule_aws_config_snapshot_bucket | Name of the S3 bucket AWS Config is using to store the snapshot files            | string |
| terraform_compliance_rule_parameters                 | Map of custom terraform compliance rule parameters                               | map    |
| terraform_compliance_rule_tags                       | Map of tags to apply to terraform compliance resources that have tags parameters | map    |
| terraform_compliance_rule_tfstate_s3_bucket          | Name of the S3 bucket Terraform is using to store the tfstate files              | string |
| config_is_enabled                                    | Flag indicating that AWS Config is active and recording                          | string |
| name_space                                           | Name space for this terraform run                                                | string |

### NewRelic Integration

| Name                                   | Description                                        | Type   |
| -------------------------------------- | -------------------------------------------------- | :----: |
| nr_integration_role_name               | Name for NewRelic Role                             | string |
| nr_integration_view_budget_policy_name | Inline policy name for NewRelic view budget policy | string |

### VPC

| Name     | Description                                             | Type   |
| -------- | ------------------------------------------------------- | :----: |
| vpc_cidr | Classless Inter-Domain Routing (CIDR) block for the VPC | string |
| vpc_name | Name for the VPC                                        | string |
| aws_azs  | Availability Zones to create VPC                        | list   |

### Subnets

| Name                                                   | Description                                                                                                  | Type   |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ | :----: |
| subnets_associate_s3_endpoint_with_private_route_table | Specify true to indicate that instances launched into the additional private subnets should have route to s3 | string |
| subnets_create_nacl_for_private_subnets                | create seperate NACL for additional private subnets.If 'flase', default NACL is assigned to the subnets      | string |
| subnets_number_of_additional_private_subnets           | Number of additional subnets for data tier services                                                          | string |

### KMS Interface
| Name                          | Description                                                              | Type   |
| ----------------------------- | ------------------------------------------------------------------------ | :----: |
| type_of_service_for_kms       | Type of endpoint interface service                                       | string |
| endpoint_service_name_for_kms | Endpoint interface service name                                          | string |
| private_dns_enabled_for_kms   | Whether or not to associate a private hosted zone with the specified VPC | string |

### SNS Interface 
| Name                          | Description                                                              | Type   |
| ----------------------------- | ------------------------------------------------------------------------ | :----: |
| type_of_service_for_sns       | Type of endpoint interface service                                       | string |
| endpoint_service_name_for_sns | Endpoint interface service name                                          | string |
| private_dns_enabled_for_sns   | Whether or not to associate a private hosted zone with the specified VPC | string |

### Egress Proxy

| Name                                 | Description                                                            | Type   |
| ------------------------------------ | ---------------------------------------------------------------------- | :----: |
| egress_cloudwatch_log_group_name     | cloudwatch log group name for squid audit logs                         | string |
| egress_cloudwatch_log_retention_days | Number of days for egress audit log to retain                          | string |
| egress_instance_type                 | EC2 instance type for Squid proxy to run                               | string |
| egress_max_number_instances          | Maximum number of egress instances to create during auto sclaing event | string |
| egress_proxy_name                    | Name for Egress proxy                                                  | string |
| egress_s3_bucket_name_prefix         | S3 bucket name for proxy information                                   | string |

### FlowLogs

| Name                              | Description                                                      | Type   |
| --------------------------------- | ---------------------------------------------------------------- | :----: |
| flow_logs_group_retention_in_days | Number of days to retain vpc flow logs                           | string |
| flow_logs_traffic_type            | The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL | string |

### Route53

| Name                      | Description                                         | Type   |
| ------------------------- | --------------------------------------------------- | :----: |
| route53_parent_domain     | Parent domain name of the hosted zone to be created | string |
| route53_sub_domain_prefix | Sub domain to create zone                           | string |

### Kubernetes

| Name                      | Description                                                                                   | Type   |
| ------------------------- | --------------------------------------------------------------------------------------------- | :----: |
| k8s_ami_os_name           | Name of the os in AMI used                                                                    | string |
| k8s_ami_owner             | Owner of the AMI to be used                                                                   | string |
| k8s_ami_unique_identifier | AMI name unique identifier                                                                    | string |
| k8s_cluster_name          | Name of the Kubernetes cluster                                                                | string |
| k8s_master_count          | Number of master nodes                                                                        | string |
| k8s_master_instance_type  | master ec2 instance type                                                                      | string |
| k8s_node_count_max        | Max number of worker nodes                                                                    | string |
| k8s_node_count_min        | Min number of worker nodes                                                                    | string |
| k8s_node_instance_type    | worker ec2 instance type                                                                      | string |
| k8s_pekops_trigger        | changing this value effectively trigger pekops again , this would mean creating a new cluster | string |
| k8s_s3_bucket_name        | S3 bucket name to store the K8s State. Must be unique                                         | string |

### RDS Aurora

| Name                                         | Description                                                                                                 | Type   |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | :----: |
| rds_apply_changes_immediately                | Specifies whether any cluster modifications are applied immediately, or during the next maintenance window  | string |
| rds_aurora_data_import_s3_bucket_name_prefix | S3 bucket name prefix for importing the data to aurora db                                                   | string |
| rds_backup_retention_period                  | The days to retain backups for                                                                              | string |
| rds_cluster_parameter_family                 | RDS sql family for cluster parameter group                                                                  | string |
| rds_database_engine                          | RDS database engine type to be used for this DB cluster [aurora,aurora-mysql OR aurora-postgresql]          | string |
| rds_database_identifier                      | Must be unique for all DB instances per AWS account, per region                                             | string |
| rds_instance_class                           | The instance Class is based on CPU and Memory to use                                                        | string |
| rds_instance_port                            | The port on which the DB accepts connections                                                                | string |
| rds_master_password                          | Master password for all databases running in the instance.Name constraints differ for each database engine  | string |
| rds_master_username                          | Master username for all databases running in the instance.Name constraints differ for each database engine  | string |
| rds_monitoring_interval                      | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance | string |
| rds_no_of_read_instances                     | Number of read instancses to launch along with one read-write instance in the cluster. Minimum is 1         | string |

### Redis

| Name                           | Description                                                                                                                                                                            | Type   |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----: |
| redis_cache_description        | The redis cache replication group description                                                                                                                                          | string |
| redis_cache_identifier         | The redis cache identifier                                                                                                                                                             | string |
| redis_desired_nodes            | The number of cache clusters this replication group will have. If Multi-AZ is enabled , the value of this parameter must be at least 2                                                 | string |
| redis_maintenance_window       | Specifies the weekly time range for when maintenance on the cache cluster is performed. The format is ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC).                                         | string |
| redis_node_type                | The compute and memory capacity of the nodes in the node group.                                                                                                                        | string |
| redis_password                 | The password used to access a password protected server. Can be specified only if transit_encryption_enabled = true                                                                    | string |
| redis_port                     | The port number of the Redis Cache endpoint                                                                                                                                            | string |
| redis_snapshot_retention_limit | The number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them . If the SnapshotRetentionLimit is set to zero (0), backups are turned off | string |
| redis_snapshot_window          | The daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot of your cache cluster                                                                        | string |

### EFS

| Name                         | Description                                                                 | Type   |
| ---------------------------- | --------------------------------------------------------------------------- | :----: |
| efs_kms_key_description      | Description of the efs kms key                                              | string |
| efs_kms_key_is_enabled       | Specifies whether the efs kms key is enabled                                | string |
| efs_kms_key_rotation_enabled | Specifies whether the efs kms key rotation is enabled                       | string |
| efs_performance_mode         | The efs file system performance mode. Can be either generalPurpose or maxIO | string |

### Elastic Search

| Name                                     | Description                                                                                     | Type   |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------- | :----: |
| elastic_cluster_dedicated_master_count   | Number of dedicated master nodes in the cluster.                                                | string |
| elastic_cluster_dedicated_master_enabled | Indicates whether dedicated master nodes are enabled for the cluster.                           | string |
| elastic_cluster_instance_count           | Number of instances in the cluster.                                                             | string |
| elastic_cluster_instance_type            | Instance type of data nodes in the cluster.                                                     | string |
| elastic_cluster_master_instance_type     | Instance type of master nodes in the cluster                                                    | string |
| elastic_cluster_zone_awareness_enabled   | Indicates whether zone awareness is enabled.                                                    | string |
| elastic_domain_identifier                | Name of the elastic search domain                                                               | string |
| elastic_ebs_options_enabled              | Whether EBS volumes are attached to data nodes in the domain.                                   | string |
| elastic_ebs_options_volume_size          | The size of EBS volumes attached to data nodes (in GB). Required if ebs_enabled is set to true. | string |
| elastic_ebs_options_volume_type          | The type of EBS volumes attached to data nodes.Allowed values:gp2 ,io1 ,standard                | string |
| elastic_kms_key_description              | Description of the kms key                                                                      | string |
| elastic_kms_key_is_enabled               | Specifies whether the kms key is enabled                                                        | string |
| elastic_kms_key_rotation_enabled         | Specifies whether the kms key rotation is enabled                                               | string |
| elastic_snapshot_start_hour              | Hour during which the service takes an automated daily snapshot of the indices in the domain.   | string |
| elastic_version                          | The version of ElasticSearch to deploy.                                                         | string |

### ECR

| Name                             | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Type   |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----: |
| ecr_repository_policy_enforced   | Boolean Flag to enable repository policy for the ECR repository                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | string |
| ecr_lifecycle_policy_enforced    | Boolean Flag to enable lifecycle policy for the ECR repository                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | string |
| ecr_repository_[ApplicationName] | The repository name to use for the ECR repository. The ApplicationName could be one of: aa, admin-gateway, admin_service, api_docs, api_gateway, application_service, audit_service, auth_manager, config_server, encryption-service, dbupdate, dbmigrate, external_dns, filebeat, invitation_service, kube-state-metrics, notification_service, nr_infra, oauth_server, oidc_provider, pumba, sample-app, security_policy, service_gateway, service_registry, spring_admin, stress, tag_service, tenant_service, user_service, zipkin, cloud-tasks, java-ssl-server, java-ssl-client, pem-store-utility, magic-server | string |

### CodeCommit

| Name                         | Description                                               | Type   |
| ---------------------------- | --------------------------------------------------------- | :----: |
| code_commit_repo_description | The repository description                                | string |
| code_commit_repository_name  | The repository name to use for the Code Commit repository | string |

### OID S3 Bucket for All CI/CD

| Name                          | Description                                    | Type   |
| ----------------------------- | ---------------------------------------------- | :----: |
| oid_all_s3_bucket_name_prefix | Log bucket name prefix for all CI/CD workflows | string |

### S3 Logging Bucket

| Name                            | Description                                                                                                              | Type   |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | :----: |
| s3_logging_bucket_force_destroy | A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error | string |
| s3_logging_bucket_name_prefix   | s3 logging bucket name                                                                                                   | string |

### Lambda@Edge

| Name                        | Description                         | Type   |
| --------------------------- | ----------------------------------- | :----: |
| lambda_function_name_for_cf | lambda function name for CloudFront | string |
| lambda_role_name_for_cf     | lambda IAM role for the execution   | string |

### CloudFront

| Name                                                                 | Description                                                                                                                                                                                                            | Type   |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----: |
| cf_distribution_aliases                                              | CNAMEs for this distribution                                                                                                                                                                                           | list   |
| cf_route53_zone_domain                                               | Parent domain to create Cloud Front records                                                                                                                                                                            | string | 
| cf_distribution_comment                                              | Comments you want to include about the distribution                                                                                                                                                                    | string |
| cf_distribution_default_root_object                                  | The object that you want CloudFront to return (for example, index.html) when an end user requests the root URL                                                                                                         | string |
| cf_distribution_enabled                                              | Whether the distribution is enabled to accept end user requests for content                                                                                                                                            | string |
| cf_distribution_http_version                                         | The maximum HTTP version to support on the distribution. Allowed values are http1.1 and http2                                                                                                                          | string |
| cf_distribution_is_ipv6_enabled                                      | Enable users on IPv6 networks to access distribution contents                                                                                                                                                          | string |
| cf_distribution_logging_config_access_log_prefix                     | String that you want CloudFront to prefix to the access log filenames for this distribution                                                                                                                            | string |
| cf_distribution_logging_config_include_cookies                       | Specifies whether you want CloudFront to include cookies in access logs                                                                                                                                                | string |
| cf_distribution_price_class                                          | The price class for this distribution. One of PriceClass_All, PriceClass_200(United States,Canada,Europe,Hong Kong,Japan,India,Philippines, S. Korea, Singapore & Taiwan), PriceClass_100(United States,Canada,Europe) | string |
| cf_distribution_viewer_certificate_acm_certificate_arn               | The ARN of the AWS Certificate Manager certificate that you wish to use with this distribution.The ACM certificate must be in US-EAST-1                                                                                | string |
| cf_distribution_viewer_certificate_iam_certificate_id                | The IAM certificate identifier of the custom viewer certificate for this distribution if you are using a custom domain                                                                                                 | string |
| cf_distribution_viewer_certificate_is_cloudfront_default_certificate | Use cloudfront default certificate if only if CloudFront domain name is used for your distribution                                                                                                                     | string |
| cf_distribution_viewer_certificate_minimum_protocol_version          | he minimum version of the SSL protocol that you want CloudFront to use for HTTPS connections. One of TLSv1, TLSv1_2016, TLSv1.1_2016 or TLSv1.2_2018                                                                   | string |
| cf_distribution_viewer_certificate_ssl_support_method                | Specifies how you want CloudFront to serve HTTPS requests. One of vip or sni-only.vip causes CloudFront to use a dedicated IP address and may incur extra charges.                                                     | string |
| cf_distribution_web_acl_id                                           | If you are using AWS WAF to filter CloudFront requests, the Id of the AWS WAF web ACL that is associated with the distribution                                                                                         | string |
| cf_s3_origin_path                                                    | Path to directory in S3 bucket from where cloudFront to request your content from, beginning with a /                                                                                                                  | string |
| cf_lb_origin_path                                                    | Path to directory in custom origin from where cloudFront to request your content from, beginning with a /                                                                                                              | string |
| cf_custom_origin_config_keepalive_timeout                            | The amount of time, in seconds, that CloudFront maintains an idle connection with a custom origin server before closing the connection. Valid values are from 1 to 60 seconds                                          | string |
| cf_custom_origin_config_protocol_policy                              | CloudFront to connect to your origin using only HTTP, only HTTPS, or to connect by matching the protocol used by the viewer                                                                                            | string |
| cf_custom_origin_config_read_timeout                                 | The amount of time, in seconds, that CloudFront waits for a response from a custom origin.Valid values are from 4 to 60 seconds                                                                                        | string |
| cf_custom_error_response_caching_min_ttl                             | The minimum amount of time you want HTTP error codes to stay in CloudFront caches before CloudFront queries your origin to see whether the object has been updated                                                     | string |
| cf_custom_error_response_page_path                                   | The path of the custom error page (for example, /custom_404.html)                                                                                                                                                      | string |
| cf_geo_restriction_locations                                         | The ISO 3166-1-alpha-2 codes for which you want CloudFront either to distribute your content (whitelist) or not distribute your content (blacklist)                                                                    | list   |
| cf_geo_restriction_restriction_type                                  | The ISO 3166-1-alpha-2 codes for which you want CloudFront either to distribute your content (whitelist) or not distribute your content (blacklist)                                                                    | string |
| cf_retain_on_delete                                                  | Disables the distribution instead of deleting it when destroying the resource through Terraform. If this is set, the distribution needs to be deleted manually afterwards                                              | string |
| cf_s3_bucket_static_content_versioning_enabled                       | A state of versioning                                                                                                                                                                                                  | string |
| cf_s3_origin_force_destroy                                           | Indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error                                                                                                              | string | `false` | no |
| cf_s3_static_content_bucket_name_prefix                              | The name of the bucket to store static contents                                                                                                                                                                        | string |
| cf_s3_static_content_cors_allowed_headers                            | Specifies which headers are allowed                                                                                                                                                                                    | list   |
| cf_s3_static_content_cors_allowed_methods                            | Specifies which methods are allowed. Can be GET, PUT, POST, DELETE or HEAD                                                                                                                                             | list   |
| cf_s3_static_content_cors_allowed_origins                            | Specifies which origins are allowed                                                                                                                                                                                    | list   |
| cf_s3_static_content_cors_expose_headers                             | Specifies expose header in the response                                                                                                                                                                                | list   |
| cf_s3_static_content_cors_max_age_seconds                            | Specifies time in seconds that browser can cache the response for a preflight request                                                                                                                                  | string |
| cf_dynamic_endpoint_access_logs_enabled                              | Boolean to enable / disable access_logs                                                                                                                                                                                | string |
| cf_dynamic_endpoint_access_logs_publish_interval                     | The publishing interval in minutes                                                                                                                                                                                     | string |
| cf_dynamic_endpoint_enable_cross_zone_load_balancing                 | Enable cross-zone load balancing                                                                                                                                                                                       | string |
| cf_dynamic_endpoint_idle_timeout                                     | The time in seconds that the connection is allowed to be idle                                                                                                                                                          | string |
| cf_dynamic_endpoint_listener_instance_port                           | The port on the instance to route to                                                                                                                                                                                   | string |
| cf_dynamic_endpoint_listener_lb_port                                 | The port to listen on for the load balancer                                                                                                                                                                            | string |
| cf_dynamic_endpoint_listener_lb_protocol                             | The protocol to listen on. Valid values are HTTP, HTTPS, TCP, or SSL                                                                                                                                                   | string |
| cf_dynamic_endpoint_listener_protocol                                | The protocol to use to the instance. Valid values are HTTP, HTTPS, TCP, or SSL                                                                                                                                         | string |
| cf_dynamic_endpoint_name                                             | Creates a unique name beginning with the specified prefix                                                                                                                                                              | string |
| cf_dynamic_endpoint_orgin_route53_alias_name                         | route53 alise for aws lb                        | string |

### Tenant specfic variables 

| Name                                                                 | Description                                                                                                                                                                                                            | Type   |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----: |

| tenant_1_zone_name                                                   | name of the hosted zone in the form of parent domain | string |
| tenant_1_admin_app_name                                              | name of the admin app in the form of fqdn            | string |
| tenant_1_oid_main_name                                               | name of the oid main app in the form of fqdn         | string |

### CloudFront Admin UI

| Name                                                                 | Description                                                                                                                                                                                                            | Type   |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----: |
| cf_distribution_aliases_for_admin_ui | CNAMEs for this distribution | list |
| cf_distribution_comment_for_admin_ui | Comments you want to include about the distribution | string |
| cf_distribution_viewer_certificate_acm_certificate_arn_for_admin_ui | The ARN of the AWS Certificate Manager certificate that you wish to use with this distribution.The ACM certificate must be in US-EAST-1 | string |
| cf_distribution_logging_config_access_log_prefix_for_admin_ui | String that you want CloudFront to prefix to the access log filenames for this distribution | string |
| cf_s3_origin_path_for_admin_ui | Path to directory in S3 bucket from where cloudFront to request your content from, beginning with a / | string |
| cf_s3_static_content_bucket_name_prefix_for_admin_ui | The name of the bucket to store static contents | string |


### KMS key for Auth

| Name                          | Description                                            | Type   |
| ----------------------------- | ------------------------------------------------------ | :----: |
| auth_kms_key_description      | Description of the auth kms key                        | string |
| auth_kms_key_is_enabled       | Specifies whether the auth kms key is enabled          | string |
| auth_kms_key_rotation_enabled | Specifies whether the auth kms key rotation is enabled | string |

## Outputs

| Name                            | Description                                  |
| ------------------------------- | -------------------------------------------- |
| cloudwatch_log_group_properties | Cloudwatch log properties                    |
| aws_config_properties           | aws Config properties                        |
| inspector_properties            | Inspector properties                         |
| newrelic_integration_config     | NewRelic integration properties              |
| vpc_properties                  | VPC properties                               |
| vpc_interface_endpoint_kms      | KMS interface properties                     |
| vpc_interface_endpoint_sns      | SNS vpc_interface_endpoint_sns               |
| egress_proxy_properties         | Egress proxy properties                      |
| flow_logs_properties            | VPC Flow logs properties                     |
| route53_parent_properties       | Route53 parent domain properties             |
| route53_k8s_zone_properties     | route53 k8s zone properties                  |
| k8s_properties                  | Kubernetes properties                        |
| rds_properties                  | RDS properties                               |
| redis_properties                | Redis properties                             |
| efs_properties                  | EFS properties                               |
| elastic_search_output           | Elastic Search properties                    |
| codecommit_properties           | Code Commit properties                       |
| ecr_properties                  | ECR properties                               |
| lambda_edge_properties          | Lambda Edge properties                       |
| cloud_front_properties          | Cloud Front properties                       |
|cloud_front_admin_ui_properties  | Cloud Front properties for admin UI          |
| s3_logging_bucket               | S3 logging bucket properties                 |
| s3_oid_all_bucket               | S3 oid CI/CD bucket properties               |
| auth_kms_properties             | KMS key for OID auth properties              |
| cross-account-role-properties   | Role and policy properties for cross account |
