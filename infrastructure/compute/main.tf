data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket       = var.state_bucket
    key          = "${var.state_key_prefix}/networking/terraform.tfstate"
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
    { for index in range(var.control_plane_count) : "control-plane-${index + 1}" => { role = "control-plane", subnet_index = index, instance_type = var.control_plane_instance_type } },
    { for index in range(var.worker_count) : "worker-${index + 1}" => { role = "worker", subnet_index = index, instance_type = var.worker_instance_type } },
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

}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name_prefix = "${var.project_name}-ssm-"
  role        = aws_iam_role.ssm.name
}


resource "aws_iam_policy" "s3_read" {
  name        = "${var.project_name}-s3-read"
  description = "Allow EC2 nodes to read objects from S3"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.scripts.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.ssm.name
  policy_arn = aws_iam_policy.s3_read.arn
}

resource "aws_iam_policy" "ssm_parameters_read" {
  name        = "${var.project_name}-ssm-parameters-read"
  description = "Allow EC2 nodes to read project SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]

        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_parameters_read" {
  role       = aws_iam_role.ssm.name
  policy_arn = aws_iam_policy.ssm_parameters_read.arn
}

resource "aws_instance" "node" {
  for_each = local.nodes

  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = each.value.instance_type
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

  user_data = templatefile(
  "${path.module}/user-data.sh",
  {
    SSH_PUBLIC_KEY = tls_private_key.cluster.public_key_openssh
    SSH_PRIVATE_KEY = tls_private_key.cluster.private_key_openssh
    SSH_CONFIG     = local.ssh_config
  }
  )

  tags = {
    Name = "${var.project_name}-${each.key}"
    Role = each.value.role
  }
}

#s3 bucket for storing scirpts
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "scripts" {
  bucket = "${var.project_name}-scripts-${random_id.bucket_suffix.hex}"
}

resource "aws_ssm_parameter" "scripts_bucket_name" {
  name  = "/${var.project_name}/scripts_bucket_name"
  type  = "String"
  value = aws_s3_bucket.scripts.bucket
}