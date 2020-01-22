require_relative 'code_pipeline_invoker'

def handler(event:, context:)
  code_pipeline_job = event['CodePipeline.job']

  if code_pipeline_job.nil?
    raise "CodePipeline.job not found in #{event}"
  end

  CodePipelineInvoker.new(code_pipeline_job, context.aws_request_id).audit
end