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

#s3 bucket for storing scirpts
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "scripts" {
  bucket = "${var.project_name}-scripts-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_object" "scripts" {
  for_each = fileset("${path.module}/scripts", "**")

  bucket = aws_s3_bucket.scripts.bucket

  key = "scripts/${each.value}"

  source = "${path.module}/scripts/${each.value}"

  etag = filemd5("${path.module}/scripts/${each.value}")
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