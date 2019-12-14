# e2e-release
End to end release is an automated process that fetches the below mentioned OPA artifacts - bundles them, pushes it to s3 and provides it to the e2e-release-state-machine to run necessary steps & lambdas.

### Artifacts:
* OPA Microstratergy Web: oap-mstr-web
* OPA ETLs: opa_etls
* OPA Microstartegy Content: mstr-content
* OPA Dataloader: oap-mstr-dataloader

## Usage
Run the [Build OPA Release (EAC) Jenkins pipeline](https://jenkins-opa-jenkins.ocp-elr-core-nonprod.optum.com/job/Build%20OPA%20Release%20(EAC)/) job with Parameters. Typically, you should check the useReleaseDefinition checkbox to select from a set of specific release definitions. This creates a named release.

Then you can run the [Deploy OPA Release (EAC) Jenkins pipeline](https://jenkins-opa-jenkins.ocp-elr-core-nonprod.optum.com/job/Deploy%20OPA%20Release%20(EAC)/) with parameters. Enter the name of the named release and choose the environment for deployment.
