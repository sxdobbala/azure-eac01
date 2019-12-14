# Terraform Module "secure-buckets"

Runs a lambda function which iterates over all S3 buckets in the current account and checks whether the bucket policy contains
a statement denying communications without SSL. Adds the statement to each bucket policy if it wasn't present.

The lambda is currently scheduled to run every hour.## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| is\_prod | Flag used to determine whether to create prod or non-prod resources | string | n/a | yes |
| opa\_api\_source\_code\_s3\_bucket | S3 bucket with API lambda source code | string | n/a | yes |
| opa\_api\_source\_code\_s3\_key | S3 key with API lambda source code | string | n/a | yes |

