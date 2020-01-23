describe 'Pipeline Invocation' do
  context 'Pipeline has run already with cfn-nag' do
    it 'returns a failure count' do
      pipeline_name = ENV['pipeline_name']
      execution_id = ENV['execution_id']
      puts "Execution id: #{execution_id}"
      execution_id = execution_id.chomp if execution_id
      begin
        status = `aws codepipeline get-pipeline-execution --pipeline-name #{pipeline_name} --output text --pipeline-execution-id #{execution_id} --query pipelineExecution.status`.chomp
        puts "Status: #{status}"
        sleep 15
      end until status != 'InProgress'

      jmespath_to_cfn_nag_action = 'stageStates[?stageName == `Scan`]|[0].actionStates|[0].latestExecution.errorDetails.message'
      actual_failure_message = `aws codepipeline get-pipeline-state --name #{pipeline_name} --query '#{jmespath_to_cfn_nag_action}'`.chomp

      expected_failure_message = "Failures count: 3\nWarnings count: 4\n"

      expect(actual_failure_message).to eq(expected_failure_message)
    end
  end
end