<img src="https://github.com/stelligent/cfn_nag/raw/master/logo.png?raw=true" width="150">
<br/>

## Overview
A lambda function to run [cfn_nag](https://github.com/stelligent/cfn_nag) as an action in CodePipeline.


## Installation
To install, navigate to the cfn-nag-pipeline application in the AWS Serverless Repo console and click deploy.

NOTE: due to a bug with SAM policy templates ([#389](https://github.com/awslabs/serverless-application-model/issues/389)) you will need to manually update the IAM role that the Lambda function assumes. The role should be named something like `aws-serverless-repository-cfn-n-CfnNagFunctionRole-XXXXXXXX`.  Update the inline policy named `CfnNagFunctionRolePolicy0` to set the `Resource` to `*`:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:PutJobFailureResult",
                "codepipeline:PutJobSuccessResult"
            ],
            "Resource": "*"
        }
    ]
}
```

## Reference the Lambda from Code Pipeline

* Add a source step for a repository with CloudFormation templates
* Add a downstream build step with provider `AWS Lambda`
* Select the function name `cfn-nag-pipeline`
* Select the glob for CloudFormation templates in the user parameters section for the step: e.g. `spec/test_templates/json/ec2_volume/*.json`
* Select the name of the Input Artifact from the repository

## Development

* Ensure **awscli** is installed. The credentials will need permission to create an S3 bucket, lambda functions, and an IAM role for the functions (at least)
* To run tests and build the lambda function, run: `rake`
* To deploy the function, run: `rake deploy`
