describe 'Pipeline Invocation' do
  context 'Pipeline has run already with cfn-nag' do
    it 'returns a failure count' do
      pipeline_name = ENV['pipeline_name']
      jmespath_to_cfn_nag_action = 'stageStates[?stageName == `Scan`]|[0].actionStates|[0].latestExecution.errorDetails.message'
      actual_failure_message = system("aws codepipeline get-pipeline-state --name #{pipeline_name} --query '#{jmespath_to_cfn_nag_action}'")

      expected_failure_message = "Failures count: 5\nWarnings count: 5\n"

      expect actual_failure_message.to eq expected_failure_message
    end
  end
end