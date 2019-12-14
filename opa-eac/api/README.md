# OPA API Library (AWS)

This is a library which contains API for use by the OPA team in AWS. It does not include a dependency on *psycopg2* intentionally so that you can pick which version of *psycopg2* you would like. See below for more info.

## Usage in AWS Lambda

Add the following lines to your pip requirements.txt file:

```
https://github.optum.com/opa/opa.psycopg2/archive/master.zip
https://github.optum.com/opa/opa.api/archive/master.zip
```

## Usage in AWS EC2

Add the following lines to your pip requirements.txt file:

```
psycopg2-binary
https://github.optum.com/opa/opa.api/archive/master.zip
```

