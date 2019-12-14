# opa-mstr-aws module

This is a provisioner for MSTR-instance-related resources once a client MSTR instance has been created. It does not provision resources directly but rather creates a zip archive of terraform files which is uploaded to S3 and invoked via the "tf-runner" lambda.


