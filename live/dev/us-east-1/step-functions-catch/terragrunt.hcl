include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/step-functions-catch"
}

inputs = {
  name = "aws-skill-builder-step-functions-catch"
}
