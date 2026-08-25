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