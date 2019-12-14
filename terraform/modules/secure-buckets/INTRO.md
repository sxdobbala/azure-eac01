# Terraform Module "secure-buckets"

Runs a lambda function which iterates over all S3 buckets in the current account and checks whether the bucket policy contains
a statement denying communications without SSL. Adds the statement to each bucket policy if it wasn't present.

The lambda is currently scheduled to run every hour.