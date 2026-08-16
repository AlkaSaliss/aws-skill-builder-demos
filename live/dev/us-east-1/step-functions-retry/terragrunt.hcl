include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/step-functions-retry"
}

inputs = {
  name = "aws-skill-builder-step-functions-retry"
}
