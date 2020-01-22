require 'cfn-nag'
require_relative 'code_pipeline_util'
require_relative 'clients'
require_relative 'plain_text_results'
require_relative 'plain_text_summary'


class CodePipelineInvoker
  include Clients

  def initialize(code_pipeline_job, aws_request_id)
    @aws_request_id = aws_request_id
    @code_pipeline_job = code_pipeline_job
  end

  def audit
    job_id = @code_pipeline_job['id']
    log "job_id: #{job_id}"

    audit_impl job_id
  rescue Exception => e
    log exception_message(e)
    codepipeline.put_job_failure_result failure_details: {
      type: 'JobFailed',
      message: 'Error executing cfn-nag: ' + "#{e.class}",
      **external_execution_id
    }, job_id: job_id
  end

  def log(message)
    puts message
  end

  private

  def exception_message(e)
    "Error:\n\t#{e.to_s}\nBacktrace:\n\t#{e.backtrace.join("\n\t")}"
  end

  def retrieve_cloudformation_entries
    cloudformation_entries = CodePipelineUtil.retrieve_files_within_input_artifact(
        codepipeline_event: @code_pipeline_job
    )
    log "cloudformation_entries: #{cloudformation_entries}"
    cloudformation_entries
  end

  def audit_impl(job_id)
    cloudformation_entries = retrieve_cloudformation_entries

    cfn_nag = CfnNag.new config: cfn_nag_config

    audit_results = cloudformation_entries.map do |cloudformation_entry|
      {
        name: cloudformation_entry[:name],
        audit_result: cfn_nag.audit(cloudformation_string: cloudformation_entry[:contents])
      }
    end

    put_job_result job_id, audit_results
  end

  def cfn_nag_config
    CfnNagConfig.new(
      profile_definition: nil,
      blacklist_definition: nil,
      rule_directory: nil,
      allow_suppression: true,
      print_suppression: false,
      isolate_custom_rule_exceptions: false,
      fail_on_warnings: false
    )
  end

  def any_audit_failures?(audit_results)
    audit_results.find do |audit_result|
      audit_result[:audit_result][:failure_count] > 0
    end
  end

  def external_execution_id
    {
      external_execution_id: @aws_request_id
    }
  end

  def put_job_result(job_id,
                     audit_results)
    log PlainTextResults.new.render audit_results

    audit_results_summary = PlainTextSummary.new.render audit_results

    if any_audit_failures?(audit_results)
      codepipeline.put_job_failure_result failure_details: {
        type: 'JobFailed',
        message: audit_results_summary,
        **external_execution_id
      }, job_id: job_id
    else
      codepipeline.put_job_success_result execution_details: {
        summary: audit_results_summary,
        **external_execution_id
      }, job_id: job_id
    end
  end
end
