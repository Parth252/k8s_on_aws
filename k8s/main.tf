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

resource "aws_s3_object" "scripts" {
  for_each = fileset("${path.module}/scripts", "**")

  bucket = data.terraform_remote_state.compute.outputs.scripts_bucket_name

  key = "scripts/${each.value}"

  source = "${path.module}/scripts/${each.value}"

  etag = filemd5("${path.module}/scripts/${each.value}")
}

resource "aws_ssm_association" "k8s_bootstrap" {
  depends_on = [aws_s3_object.scripts]
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