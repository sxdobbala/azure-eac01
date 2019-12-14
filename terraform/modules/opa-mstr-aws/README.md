# opa-mstr-aws module

This is a provisioner for MSTR-instance-related resources once a client MSTR instance has been created. It does not provision resources directly but rather creates a zip archive of terraform files which is uploaded to S3 and invoked via the "tf-runner" lambda.


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| s3\_artifacts\_id | S3 bucket where the archives are uploaded | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| opa\_mstr\_aws\_archive\_s3\_key | S3 key under which the opa-mstr-aws archive is stored |

