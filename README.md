![cfn_nag](https://github.com/stelligent/cfn_nag/raw/master/logo.png?raw=true "cfn_nag")

## Overview
A lambda function to run [cfn_nag](https://github.com/stelligent/cfn_nag) as an action in CodePipeline.

## Installation
To install, navigate to the [cfn-nag-pipeline](https://console.aws.amazon.com/lambda/home?region=us-east-1#/create/app?applicationId=arn:aws:serverlessrepo:us-east-1:275155842945:applications/cfn-nag-pipeline) application in the AWS Serverless Repo (SAR) console and click deploy.

### Custom Rules
The "application" deployed in SAR always reflects the latest version of cfn_nag published to [rubygems.org](https://rubygems.org/gems/cfn-nag).  This means the "core" rules should always be up to date.  That said, if you have developed custom rules, as of [0.5.5](https://github.com/stelligent/cfn_nag/releases/tag/v0.5.5) you can load those rules from an S3 bucket of your choosing.  At the point of deploying the "application" from SAR, you can select a rule bucket name and a prefix within that bucket.  Any objects with a key of the form: `prefix/\*Rule.rb` will be loaded as a cfn_nag rule.

## Reference the Lambda from AWS CodePipeline

* Add a source step for a repository with CloudFormation templates
* Add a downstream build step with provider `AWS Lambda`
* Select the function name `cfn-nag-pipeline`
* Select the glob for CloudFormation templates in the user parameters section for the step: e.g. `spec/test_templates/json/ec2_volume/*.json`
* Select the name of the Input Artifact from the repository
* For an example of such a pipeline, in this repository see: `spec/e2e/code_pipeline_using_nag.yml`

## Development

* Ensure **awscli** is installed. The credentials will need permission to create an S3 bucket, lambda functions, and an IAM role for the functions (at least)
* To run tests and build the lambda function, run: `rake`
* To deploy the function, run: `rake deploy`
