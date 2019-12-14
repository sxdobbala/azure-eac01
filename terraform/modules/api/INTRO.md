# OPA API

### Steps to Add a New API Method

Given a resource name like "new-resource" we can create a new API method as follows:

- Create subfolder api/new-resource and add the lambda python code + dependencies
- Copy opa-master.tf and rename to "new-resource.tf"
- Update "locals" in "new-resource.tf" with the desired values for the new method and lambda