data "terraform_remote_state" "compute" {
  backend = "s3"

  config = {
    bucket       = var.state_bucket
    key          = "${var.state_key_prefix}/compute/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

resource "aws_ssm_association" "k8s_bootstrap" {
  for_each = data.terraform_remote_state.compute.outputs.node_instance_ids

  name = "AWS-RunShellScript"

  association_name = "kubernetes-bootstrap-${each.key}"

  targets {
    key    = "InstanceIds"
    values = [each.value]
  }

  parameters = {
    commands = file("${path.module}/scripts/bootstrap-node.sh")
  }
}