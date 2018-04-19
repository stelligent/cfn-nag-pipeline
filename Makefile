AWS_DEFAULT_REGION ?= $(shell aws configure get region)
AWS_ACCOUNT ?= $(shell aws sts get-caller-identity --output text --query 'Account')
BUCKET_NAME ?= cfn-nag-pipeline-$(AWS_ACCOUNT)-$(AWS_DEFAULT_REGION)
VERSION ?= 0.3.47

default: build

deps:
	@echo "[INFO] installing bundler"
	@gem install -N bundler
	
	@echo "[INFO] installing dependencies from Gemfile"
	@bundle install --jobs 8
	
	@echo "[INFO] installing cfn_nag $(VERSION)"
	@gem install -N cfn-nag -v $(VERSION)

check: deps
	@echo "[INFO] validating cfn template"
	@aws cloudformation validate-template --template-body file://lambda.yml
	
	@echo "[INFO] running rspec"
	@rspec
	
build: check
	@echo "[INFO] packaging jar file"
	@mvn -Dcfnnag.version=$(VERSION) -Dversion=$(VERSION) package
	
bucket:
	@echo "[INFO] upserting bucket $(BUCKET_NAME)"
	@aws s3api head-bucket --bucket $(BUCKET_NAME) > /dev/null 2>&1 || (aws s3 mb s3://$(BUCKET_NAME) && sleep 10)
	@aws s3api put-bucket-policy --bucket $(BUCKET_NAME) --policy '{"Version":"2012-10-17","Statement":[{"Action":["s3:GetObject"],"Effect":"Allow","Resource":"arn:aws:s3:::$(BUCKET_NAME)/*","Principal":"*"}]}'
	
stage: build bucket
	@echo "[INFO] staging lambda zip"
	@aws cloudformation package --template-file lambda.yml --s3-bucket $(BUCKET_NAME) --output-template-file target/lambda.yml

sar: stage
	@aws serverlessrepo get-application --application-id arn:aws:serverlessrepo:$(AWS_DEFAULT_REGION):$(AWS_ACCOUNT):applications/cfn-nag-pipeline > /dev/null 2>&1 || \
	 aws serverlessrepo create-application --author Stelligent --description "A lambda function to run cfn_nag as an action in CodePipeline" \
	 --labels codepipeline cloudformation cfn_nag --readme-body https://raw.githubusercontent.com/stelligent/cfn_nag/master/README.md --name "cfn-nag-pipeline" --spdx-license-id MIT
	
	@echo "[INFO] creating new application version $(VERSION)"
	@aws serverlessrepo create-application-version --application-id arn:aws:serverlessrepo:$(AWS_DEFAULT_REGION):$(AWS_ACCOUNT):applications/cfn-nag-pipeline --source-code-url github.com/stelligent/cfn_nag --template-body file://target/lambda.yml --region $(AWS_DEFAULT_REGION) --semantic-version $(VERSION)
	
deploy: stage
	@aws cloudformation deploy --template-file target/lambda.yml --stack-name aws-serverless-repository-cfn-nag-pipeline \
          --capabilities CAPABILITY_NAMED_IAM \
          --parameter-overrides PipelineBucketName="*" 

clean:
	@mvn -Dversion=$(VERSION) clean
    
.PHONY: default deps check build bucket stage deploy clean
