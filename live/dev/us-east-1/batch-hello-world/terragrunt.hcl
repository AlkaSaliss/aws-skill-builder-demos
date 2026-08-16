include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/batch-hello-world"
}

inputs = {
  name = "aws-skill-builder-batch-hello-world"
}
