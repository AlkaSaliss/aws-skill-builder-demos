include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/step-functions-pass"
}

inputs = {
  name       = "skill-builder-step-functions-baseline"
  definition = file("${get_terragrunt_dir()}/../../../../resources/hello_world_from_aws_workshop.asl.json")
}
