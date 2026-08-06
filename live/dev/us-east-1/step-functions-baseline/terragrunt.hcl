include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/step-functions-pass"
}

inputs = {
  name = "skill-builder-step-functions-baseline"
}
