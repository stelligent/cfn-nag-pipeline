## Pre-requisites

0. Install Maven (Java)
   * For more information see: https://maven.apache.org/install.html

1. Configure credentials for an AWS account in the environment
   * The credentials will need permission to create an S3 bucket, lambda functions, and an IAM role for the functions (at least)
    
2. An S3 bucket to stage the packsged lambda and template to
   * `make bucket`
 
## Build the cfn-nag lambda

`make`

## Package the lambda and stage to S3

`make stage`

## Deploy new revision to Serverless Repo

`make sar`

## Reference the Lambda from Code Pipeline

0. Add a source step for a repository with CloudFormation templates
1. Add a downstream build step with provider `AWS Lambda`
2. Select the function name `cfn-nag-pipeline`
3. Select the glob for CloudFormation templates in the user parmaeters section for the step: e.g. `spec/test_templates/json/ec2_volume/*.json`
4. Select the name of the Input Artifact from the repository


TODO: 
1. Output Artifacts vs. dummping to CW logs
2. Release process/CI/pipeline for the lambda
3. Keep the underlying gem and the lambda in tandem?