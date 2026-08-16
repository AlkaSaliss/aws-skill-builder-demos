include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "batch" {
  config_path = "../batch-hello-world"
}

terraform {
  source = "../../../../modules/step-functions-batch"
}

inputs = {
  name = "aws-skill-builder-step-functions-batch"

  definition = templatefile("${get_terragrunt_dir()}/../../../../resources/run_batch_job.asl.json", {
    job_queue_arn      = dependency.batch.outputs.job_queue_arn
    job_definition_arn = dependency.batch.outputs.job_definition_arn
  })
}
