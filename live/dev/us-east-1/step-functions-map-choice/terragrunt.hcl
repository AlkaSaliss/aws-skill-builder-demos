include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/step-functions-map-choice"
}

inputs = {
  name = "aws-skill-builder-step-functions-map-choice"
}
