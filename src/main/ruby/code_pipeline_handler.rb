$lambdaLogger.log "LOAD_PATH: #{$LOAD_PATH}"
$LOAD_PATH << 'uri:classloader:/'

require 'code_pipeline_invoker'

CodePipelineInvoker.new.audit

'Complete.'
