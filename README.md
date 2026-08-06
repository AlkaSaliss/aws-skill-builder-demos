# AWS Skill Builder demos

Demos and exercises from AWS Skill Builder courses.

## Terraform and Terragrunt baseline

The repository separates reusable Terraform code from deployable Terragrunt
stacks:

```text
root.hcl  Shared provider and input configuration
modules/
  step-functions-pass/  Single-Pass Step Functions module
live/
  dev/
    us-east-1/
      region.hcl
      step-functions-baseline/  Deployable Terragrunt unit
```

The
[`live/dev/us-east-1/step-functions-baseline`](live/dev/us-east-1/step-functions-baseline)
unit consumes [`modules/step-functions-pass`](modules/step-functions-pass) and
includes the root [`root.hcl`](root.hcl) for the shared AWS provider setup. The
region is defined by `live/dev/us-east-1/region.hcl`. US East (N. Virginia) is
a sensible cost-oriented default for this demo, but AWS pricing varies by
service and region; this is not a claim that `us-east-1` is universally the
cheapest region. This initial test
deployment contains a state machine with one successful `Pass` state and its
IAM execution role. The role has only the Step Functions trust policy because
the state machine invokes no AWS services.

State is strictly local. Because Terragrunt runs sourced modules from its cache,
Terraform's implicit local state is stored under
`live/dev/us-east-1/step-functions-baseline/.terragrunt-cache` when there is
managed infrastructure. Do not delete that directory while its state is in
use. No backend block, remote-state configuration, S3 bucket, or state-locking
service is configured.

### Prerequisites

- Terraform 1.15.8
- Terragrunt 1.0.4
- AWS credentials available through the standard AWS credential chain

With the required asdf plugins already available, install the versions pinned
in `.tool-versions` without changing global defaults:

```shell
make install-tools
```

### Run locally

```shell
cd live/dev/us-east-1/step-functions-baseline
# Optional override; the default profile is CLI-MFA-USER.
export AWS_PROFILE="your-other-profile"

terragrunt init
terragrunt plan
```

Run `terragrunt apply` only after reviewing the plan. The initial plan creates
the state machine and its execution role.

The root `Makefile` provides formatting, initialization, validation, and the
standard deployment lifecycle:

```shell
make install-tools  # Install project-pinned tools with asdf
make plan     # Preview changes
make apply    # Apply after interactive approval
make destroy  # Destroy after interactive approval
```

Make defaults to `AWS_PROFILE=CLI-MFA-USER`, `AWS_REGION=us-east-1`, and
`STACK=step-functions-baseline`, constructing the live path as
`live/dev/$(AWS_REGION)/$(STACK)`. Command-line Make variables or exported
environment variables override those defaults. The selected live directory
must exist:

```shell
AWS_PROFILE="another-profile" AWS_REGION="us-east-1" \
  STACK="step-functions-baseline" make plan
```

### Use temporary MFA credentials

Generate temporary MFA credentials outside this repository. By default, Make
and Terragrunt select the `CLI-MFA-USER` AWS CLI profile. To use another profile,
export `AWS_PROFILE` in the deployment shell before running a command:

```shell
export AWS_PROFILE="your-temporary-profile"
make plan
```

The repository does not generate, read, or store credential values.
