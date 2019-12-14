# Test Suite - opa.api

This is a test suite for the opa.api package which can be executed locally without having to deploy lambdas. 

## Requirements

In order to use the test suite *pipenv* is required. You also need to be authenticaten with AWS to execute tests.

```
brew install pipenv
```

## Executing Tests

```
# install dependencies and initialize test environment
pipenv install pytest --dev

# run all tests
pipenv run pytest -v -s tests
```