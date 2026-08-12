data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket       = var.terraform_state_bucket_name
    key          = "k8s-on-aws/networking/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  nodes = merge(
    { for index in range(3) : "control-plane-${index + 1}" => { role = "control-plane", subnet_index = index } },
    { for index in range(3) : "worker-${index + 1}" => { role = "worker", subnet_index = index } },
  )

  common_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "Terraform"
    },
    var.tags,
  )
}

resource "aws_iam_role" "ssm" {
  name_prefix = "${var.project_name}-ssm-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name_prefix = "${var.project_name}-ssm-"
  role        = aws_iam_role.ssm.name
}

resource "aws_instance" "node" {
  for_each = local.nodes

  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.networking.outputs.public_subnet_ids[each.value.subnet_index]
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.node_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}"
    Role = each.value.role
  })
}
