# AWS Skill Builder demos

Demos and exercises from AWS Skill Builder courses.

## Terraform and Terragrunt baseline

The repository separates reusable Terraform code from deployable Terragrunt
stacks:

```text
root.hcl  Shared provider and input configuration
modules/
  step-functions-pass/  Single-Pass Step Functions module
  step-functions-batch/ Step Functions module for running an AWS Batch job
  step-functions-callback-sqs/  SQS callback-token workflow module
  step-functions-retry/  Step Functions Lambda retry module
  step-functions-catch/  Step Functions Lambda catch module
  step-functions-parallel/  Step Functions parallel Lambda module
  batch-hello-world/    Fargate-based AWS Batch Hello World module
live/
  dev/
    us-east-1/
      region.hcl
      step-functions-baseline/  Deployable Terragrunt unit
      batch-hello-world/        Deployable Terragrunt unit
      step-functions-batch/     Deployable Terragrunt unit
      step-functions-callback-sqs/  Deployable Terragrunt unit
      step-functions-retry/     Deployable Terragrunt unit
      step-functions-catch/     Deployable Terragrunt unit
      step-functions-parallel/  Deployable Terragrunt unit
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

### Build and push the Batch image

The module creates the ECR repository and configures the Batch job definition
to use its URI. The container runs `aws s3api list-buckets` and prints the
bucket names. Its task role is limited to `s3:ListAllMyBuckets`. Apply the
module first, then build and push the image in
[`resources/batch-hello-world/Dockerfile`](resources/batch-hello-world/Dockerfile):

```shell
AWS_PROFILE="your-profile" AWS_REGION="us-east-1" \
  ECR_REPOSITORY="aws-skill-builder-batch-hello-world" \
  IMAGE_TAG="latest" DOCKER_PLATFORM="linux/amd64" make batch-image-push
```

The module's `name` must match `ECR_REPOSITORY` when using the Make target.

### SQS callback-token workflow

The
[`live/dev/us-east-1/step-functions-callback-sqs`](live/dev/us-east-1/step-functions-callback-sqs)
stack creates a JSONata Step Functions state machine, an SQS queue, and a
Python Lambda worker, plus success and failure SNS topics. Step Functions sends
a task token to SQS and waits; the Lambda polls the queue and sends task success
two-thirds of the time or task failure one-third of the time. The state machine
publishes the callback result to the corresponding SNS topic.

```shell
AWS_REGION=us-east-1 STACK=step-functions-callback-sqs make plan
AWS_REGION=us-east-1 STACK=step-functions-callback-sqs make apply
```

The Step Functions stack depends on the Batch stack and runs its S3 bucket
listing job synchronously. Apply the Batch stack and push its image first:

```shell
AWS_REGION=us-east-1 STACK=batch-hello-world make apply
make batch-image-push
AWS_REGION=us-east-1 STACK=step-functions-batch make plan
AWS_REGION=us-east-1 STACK=step-functions-batch make apply
```

The Batch stack is deployed with:

```shell
AWS_REGION=us-east-1 STACK=batch-hello-world make plan
AWS_REGION=us-east-1 STACK=batch-hello-world make apply
AWS_REGION=us-east-1 ECR_REPOSITORY=aws-skill-builder-batch-hello-world \
  make batch-image-push
```

### Step Functions retry workflow

The retry stack invokes a Python Lambda that always raises `CustomError`. The
state machine retries that error twice, starting at one second and doubling the
backoff each time.

```shell
AWS_REGION=us-east-1 STACK=step-functions-retry make plan
AWS_REGION=us-east-1 STACK=step-functions-retry make apply
```

### Step Functions catch workflow

The catch stack invokes a Python Lambda that randomly selects `CustomError`, a
Task timeout, or a generic error with equal probability. The state machine
routes those outcomes to `CustomErrorFallback`, `TimeoutFallback`, or
`CatchAllFallback`.

```shell
AWS_REGION=us-east-1 STACK=step-functions-catch make plan
AWS_REGION=us-east-1 STACK=step-functions-catch make apply
```

### Step Functions parallel workflow

The parallel stack sends `{"numbers": [1, 2, 3]}` to three Lambda branches that
compute the sum, minimum/maximum, and average independently.

```shell
AWS_REGION=us-east-1 STACK=step-functions-parallel make plan
AWS_REGION=us-east-1 STACK=step-functions-parallel make apply
```
