require 'yaml'
require 'rspec/core/rake_task'

#AWS_DEFAULT_REGION = `aws configure get region`.chomp
AWS_DEFAULT_REGION = 'us-east-1'
AWS_ACCOUNT_ID = `aws sts get-caller-identity --output text --query 'Account'`.chomp
LAMBDA_DEPLOYMENT_CFN_STACK_NAME = 'aws-serverless-repository-cfn-nag-pipeline'

build_properties = {
  'dev' => {
    'public_visibility' => false
  },
  'prod' => {
    'public_visibility' => true
  }
}

RSpec::Core::RakeTask.new(:spec) do |task|
  task.exclude_pattern = 'spec/e2e/*.rb'
end

task default: [:test]

task test: [:spec] do
  puts '[INFO] validating cfn template'
  sh "aws cloudformation validate-template --template-body file://lambda.yml --profile labs-auto --region #{AWS_DEFAULT_REGION}"
end

task :bucket, :bucket_name do |task, args|
  bucket_name = args[:bucket_name]
  bucket_policy = <<END
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::#{bucket_name}/*",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "serverlessrepo.amazonaws.com"
        ]
      }
    }
  ]
}
END
  bucket_policy = bucket_policy.gsub("\n",'')

  puts "[INFO] upserting bucket #{bucket_name}"
  sh "aws s3api head-bucket --bucket #{bucket_name} > /dev/null 2>&1 || (aws s3 mb s3://#{bucket_name} && sleep 10)"
  sh "aws s3api put-bucket-policy --bucket #{bucket_name} --policy '#{bucket_policy}'"
end

task :stage, :target_env do |task, args|
  puts "[INFO] staging lambda zip"
  bucket_name = "cfn-nag-pipeline-#{args[:target_env]}-#{AWS_DEFAULT_REGION}"

  Rake::Task['bucket'].invoke(bucket_name)

  sh 'bundle install --path lib/vendor/bundle --without test'
  sh 'mkdir target || true'
  sh "aws cloudformation package --template-file lambda.yml --s3-bucket #{bucket_name} --output-template-file target/lambda.yml"
end

task :sar, :target_env do |task, args|
  Rake::Task['stage'].invoke(args[:target_env])
  public_visibility = build_properties[args[:target_env]]['public_visibility']

  application_id = "arn:aws:serverlessrepo:#{AWS_DEFAULT_REGION}:#{AWS_ACCOUNT_ID}:applications/cfn-nag-pipeline"
  readme_url = 'https://raw.githubusercontent.com/stelligent/cfn-nag-pipeline/master/README.md'
  license_url = 'https://raw.githubusercontent.com/stelligent/cfn-nag-pipeline/master/LICENSE.md'
  source_code_url = 'https://github.com/stelligent/cfn-nag-pipeline'
  create_application_if_necessary_command = <<END
aws serverlessrepo get-application --application-id  #{application_id} > /dev/null 2>&1 || \
     aws serverlessrepo create-application --author Stelligent \
                                           --description "A lambda function to run cfn_nag as an action in CodePipeline" \
                                           --labels codepipeline cloudformation cfn_nag \
                                           --readme-body #{readme_url} \
                                           --spdx-license-id MIT \
                                           --license-body #{license_url} \
                                           --source-code-url #{source_code_url} \
                                           --name "cfn-nag-pipeline"
END
  sh create_application_if_necessary_command

  if public_visibility
    app_visibility_command = <<END
aws serverlessrepo put-application-policy --region #{AWS_DEFAULT_REGION} \
                                          --application-id #{application_id} \
                                          --statements Principals=*,Actions=Deploy
END
  else
    app_visibility_command = <<END
aws serverlessrepo put-application-policy --region #{AWS_DEFAULT_REGION} \
                                          --application-id #{application_id} \
                                          --statements '[]'
END
  end
  sh app_visibility_command

  gem_listing_of_cfn_nag = `gem list -q cfn-nag`.chomp
  cfn_nag_version = gem_listing_of_cfn_nag.split('(')[1].split(')')[0]

  puts "[INFO] creating new application version #{cfn_nag_version}"
  create_application_version_command = <<END
aws serverlessrepo create-application-version --application-id #{application_id} \
                                              --source-code-url #{source_code_url} \
                                              --template-body file://target/lambda.yml \
                                              --region #{AWS_DEFAULT_REGION} \
                                              --semantic-version #{cfn_nag_version}
END
  sh create_application_version_command
end

task :deploy do
  # the bucket name is coupled with the code_pipeline_using_nag.yml cfn template
  # could just '*' here to decouple but of course then this lambda can read from every bucket in the account
  deploy_command = <<END
aws cloudformation deploy --template-file target/lambda.yml \
                          --stack-name #{LAMBDA_DEPLOYMENT_CFN_STACK_NAME} \
                          --capabilities CAPABILITY_NAMED_IAM \
                          --parameter-overrides PipelineBucketName="*codepipelineartifactstorebucket*"
END
  sh deploy_command
end

task :undeploy do
  undeploy_command = <<END
aws cloudformation delete-stack -stack-name #{LAMBDA_DEPLOYMENT_CFN_STACK_NAME}
END
  sh undeploy_command
end