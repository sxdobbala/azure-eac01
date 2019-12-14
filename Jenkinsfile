#!/usr/bin/env groovy
@Library(["com.optum.jenkins.pipeline.library"]) _
import groovy.transform.Field

String getRepoName() {
  return "$GIT_URL".tokenize('/')[3].split("\\.")[0]
}

String getRepoOwnerName() {
  return "$GIT_URL".tokenize('/')[2].split("\\.")[0]
}

@Field
boolean autoApprove = false

@Field
boolean is_prod = false

@Field
boolean proceed = false

@Field
String deployApprovers = ''

pipeline {
    options
    {
        disableConcurrentBuilds()
        ansiColor('xterm')
        skipStagesAfterUnstable()
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '2'))
    }
    environment {
        TERRAFORM_VERSION = "0.11.14"
        PYTHON_VERSION = "3.6"
        GIT_CREDENTIALS_ID = 'GH_TOKEN_BUILD_ACCOUNT'
        AWS_REGION = "us-east-1"
        NONPROD_AWS_ROLE = "arn:aws:iam::760182235631:role/AWS_760182235631_Service"
        NONPROD_AWS_CREDENTIAL_ID = "AWS_OPA_NONPROD_SERVICE_ACCOUNT"
        PROD_AWS_ROLE = "arn:aws:iam::029620356096:role/AWS_029620356096_Service"
        PROD_AWS_CREDENTIAL_ID = "AWS_OPA_PROD_SERVICE_ACCOUNT"
    }
    parameters
    {
        choice(
            name: 'terraformAction',
            choices: ['noop', 'apply', 'destroy'],
            description: 'Terraform Action')
        choice(
            name: 'buildEnvironment',
            choices: ['dev', 'qa', 'stage', 'prod', 'ci', 'nonprod-shared', 'prod-shared'],
            description: 'Build Environment')
        booleanParam(
          defaultValue: false,
          name: 'autoApprove',
          description: 'Allow apply to happen without approval. Only usable on lower envi'
        )
        booleanParam(
          defaultValue: false,
          name: 'forceSonar',
          description: 'Force a sonar scan'
        )
    }
    agent
    {
        node {
            label 'docker-terraform-slave'
        }
    }
    stages
    {
        stage('Checkout')
        {
            steps
            {
                checkout scm
            }
        }
        stage('Resolve Parameters')
        {
          steps {
            script{
              sh '. /etc/profile.d/jenkins.sh'
              def userCause = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')
              env.JOB_RUNNER = userCause.userId?.find { true }

              is_prod = params.buildEnvironment in ["stage", "prod", "prod-shared"]
              autoApprove = params.autoApprove
              if (is_prod)
              {
                autoApprove = false
                deployApprovers = "mgeorgie,tvetheka,jhancoc4,${getRepoOwnerName()}";
              }
              else if (params.buildEnvironment == 'ci')
              {
                autoApprove = true
              }
              else
              {
                deployApprovers = "mgeorgie,tvetheka,jhancoc4,bfeldrih,zren";
              }
              proceed = autoApprove //if autoApprove, we should proceed
            }
          }

        }
        stage('Configure AWS')
        {
            steps
            {
                script {
                    def aws_role = is_prod ? PROD_AWS_ROLE : NONPROD_AWS_ROLE
                    def aws_cred = is_prod ? PROD_AWS_CREDENTIAL_ID : NONPROD_AWS_CREDENTIAL_ID

                    echo "Using AWS Role ${aws_role}"
                    echo "Using AWS Credential ID ${aws_cred}"

                    glAmazonGetTemporaryCredentials credentialsId: aws_cred, roleARN: aws_role, awsRegion: "${AWS_REGION}"
                    env.AWS_PROFILE = 'saml'
                    env.TERRAFORM_CONFIG_DIR = "terraform/environments/${params.buildEnvironment}"
                }
            }
        }
        stage("Run Unit Tests")
        {
            when {
              // Only run unit tests for pull request builds and with non-prod env.
              // When authenticated to production account, it is
              // not possible to WRITE to the artifacts bucket
              allOf{
                changeRequest()
                expression { is_prod == false }
              }
            }
            steps
            {
                script
                {
                    // Copy dummy tests from data folder to S3, then to D01 EC2 instance and then run pytest
                    sh """
                    cd api
                    export PYTHON_VERSION=${PYTHON_VERSION}
                    export LC_ALL=en_US.utf-8
                    export LANG=en_US.utf-8
                    . /etc/profile.d/jenkins.sh
                    export AWS_PROFILE=saml
                    aws s3 cp data/ s3://760182235631-opa-artifacts-opa/ci/dummy-tests --recursive
                    aws ssm send-command \
                      --instance-ids i-033dc99b6b35c49e0 \
	                    --document-name "AWS-RunShellScript" \
	                    --parameters commands=["aws s3 sync s3://760182235631-opa-artifacts-opa/ci/dummy-tests /home/ssm-user/"]
                    python3.6 -m venv venv
                    . venv/bin/activate
                    python -m ensurepip --upgrade
                    python -m pip install pipenv
                    pipenv install pytest --dev
                    python -m pytest -v -s tests --junitxml pytest.xml
                    """
                }
            }
            post {
              always {
                junit "api/pytest.xml"
              }
            }
        }
        stage("Sonar")
        {
          when {
            anyOf{
              changeRequest()
              expression { params.forceSonar }
            }
          }
          steps{
            script{
            def repoUrl = "https://github.optum.com/${getRepoOwnerName()}/${getRepoName()}.git"
            glSonarScan productName: getRepoOwnerName(),
              gitUserCredentialsId: "${env.GIT_CREDENTIALS_ID}",
              scmRepoUrl: repoUrl,
              sonarServer: "sonar.optum",
              sources: 'api',
              sonarExclusions: 'api/mstr/backup/*.sql',
              branchName: "${env.GIT_BRANCH}",
              mainBranchName: 'preprod'
            }
          }
        }
        stage("Init Plans")
        {
            steps
            {
              script {
                env.PLANFILE = "${params.buildEnvironment}.tfplan"
              }
              glTerraformInit terraformVersion: TERRAFORM_VERSION,
                configurationDir: env.TERRAFORM_CONFIG_DIR,
                additionalFlags: ['input':'false']
              }
        }
        stage("Validate Plans")
        {
            steps
            {
              glTerraformValidate terraformVersion: TERRAFORM_VERSION,
                configurationDir: env.TERRAFORM_CONFIG_DIR,
                additionalFlags: ['var-file':"${env.TERRAFORM_CONFIG_DIR}/terraform.tfvars"]
            }
        }
        stage("Run Plans")
        {
            steps
            {
              glTerraformPlan terraformVersion: TERRAFORM_VERSION,
                configurationDir: "terraform/environments/${params.buildEnvironment}",
                additionalFlags: ['out': env.PLANFILE, 'input': 'false',
                  'var-file':"${env.TERRAFORM_CONFIG_DIR}/terraform.tfvars"]

              archiveArtifacts artifacts: env.PLANFILE
            }
        }
        stage("Request Deploy Permission"){
          when {
            beforeInput true
            allOf
            {
              expression { params.terraformAction == "apply" }
              expression { autoApprove == false } //don't require approval for CI
            }
          }
          steps
          {
            script {
              try {
                proceed = true
                timeout(time: 10, unit: 'MINUTES') {                // timeout waiting for input after 10 minutes
                  // capture the release parameters details in releaseMap, not yet able to use glApproval method for passing parameters
                  releaseMap = input message: "Caution!!! Does ${params.buildEnvironment} plan look ok?",
                                     ok: 'Apply Plan',
                                     submitter: deployApprovers,
                                     submitterParameter: 'APPROVER'                 // Record the approver msid
                }
              } catch (err) {    // If not approved or timeout, catch the error and continue but not proceed to cut a release
                echo err.toString()
                proceed = false
              }
            }
          }
        }
        stage("Apply Changes")
        {
          when {
              beforeInput true
              allOf {
                  expression { params.terraformAction == "apply"}
                  expression { proceed == true }
              }
          }
          steps{
              environmentApply(params.buildEnvironment)
          }
        }
        stage("Destroy (CI ONLY)")
        {
            when {
                allOf {
                    expression { params.terraformAction == "destroy" }
                    expression { params.buildEnvironment in ["ci"] }
                }
            }
            steps
            {
                        echo "Destroying ${params.buildEnvironment} plan"
                        sh """#!/bin/bash -l
                        export TERRAFORM_VERSION=${TERRAFORM_VERSION}
                        . /etc/profile.d/jenkins.sh
                        export AWS_PROFILE=saml
                        cd terraform/environments/${params.buildEnvironment}
                        terraform destroy -input=false
                    """
            }
        }
    }

    post
    {
        success
        {
            emailext (
                to: "opa-aws-notify@uhg.flowdock.com",
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
        <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>"""
            )
        }
        failure
        {
            emailext (
                to: "opa-aws-notify@uhg.flowdock.com",
                subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
        <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>"""
            )
        }
    }
}

def environmentApply(String environment)
{
  script{
    def stageName = "Apply ${environment}"
    //declare a stage within a script so that we can have a dynamic stage name
    stage(stageName)
    {
      glTerraformApply terraformVersion: TERRAFORM_VERSION,
        planFile: env.PLANFILE,
        environment: environment,
        cloudProvider: 'aws',
        additionalFlags: ['input': 'false']
    }
  }
}
