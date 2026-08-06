# Shared configuration inherited by deployment stacks under live/.
locals {
  region_config = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  aws_region    = local.region_config.locals.aws_region
  aws_profile   = get_env("AWS_PROFILE", "cli-mfa-user")
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
      profile = "${local.aws_profile}"

      default_tags {
        tags = {
          ManagedBy = "Terraform"
          Project   = "aws-skill-builder-demos"
        }
      }
    }
  EOF
}
