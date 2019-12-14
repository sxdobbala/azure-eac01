# Use when a required query string or body parameter is missing
class ApiMissingRequestParameter(ValueError):
    def __init__(self, message):
        self.message = message


# Use when a client configuration setting is not found in the master db
class ApiConfigSettingNotFound(ValueError):
    def __init__(self, message):
        self.message = message


# Use when a query string or body parameter has invalid value
class ApiInvalidParameter(ValueError):
    def __init__(self, message):
        self.message = message


# Use when testing for the status of a CloudFormation stack
# Raise if status is not in set("CREATE_COMPLETE", "CREATE_FAILED", "DELETE_COMPLETE", "DELETE_FAILED")
class StackNotReadyError(ValueError):
    def __init__(self, message):
        self.message = message


# Use when testing for the status of a CloudFormation stack
# Raise if status is in set("CREATE_FAILED", "DELETE_FAILED")
class StackFailedError(ValueError):
    def __init__(self, message):
        self.message = message


# Use primarily with step functions when a step passed in the id of an object that's not found
class ClientNotFoundError(ValueError):
    def __init__(self, message):
        self.message = message
