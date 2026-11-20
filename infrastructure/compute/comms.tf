resource "aws_route53_zone" "k8s" {
  name = var.private_domain_name

  vpc {
    vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
  }
}

resource "aws_route53_record" "node" {
  for_each = aws_instance.node

  zone_id = aws_route53_zone.k8s.zone_id

  name = each.key
  type = "A"
  ttl  = 300

  records = [each.value.private_ip]
}

resource "aws_vpc_dhcp_options" "k8s" {
  domain_name = var.private_domain_name

   domain_name_servers = [
    "AmazonProvidedDNS"
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "k8s-dhcp-options"
    }
  )
}

resource "aws_vpc_dhcp_options_association" "k8s" {
  vpc_id          = data.terraform_remote_state.networking.outputs.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.k8s.id
}

#SSH configuration for the nodes

locals {
  ssh_config = join("\n", [
    for node_name, node in local.nodes : <<-SSH
Host ${node_name}
    HostName ${node_name}.k8s.internal
    User ec2-user
    IdentityFile /home/ec2-user/.ssh/k8s_cluster
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
SSH
  ])
}

resource "tls_private_key" "cluster" {
  algorithm = "ED25519"
}

#Load Balancer for the Kubernetes API server
locals {
  control_plane_nodes = {
    for name, instance in aws_instance.node :
    name => instance
    if startswith(name, "control-plane-")
  }
}

resource "aws_lb" "k8s-api-lb" {
  name               = "k8s-api-server"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.terraform_remote_state.networking.outputs.public_subnet_ids
  enable_deletion_protection = false
  security_groups = [ data.terraform_remote_state.networking.outputs.k8s_api_lb_sg_id]

}

resource "aws_lb_listener" "k8s-api-listener" {
  load_balancer_arn = aws_lb.k8s-api-lb.arn

  port     = 6443
  protocol = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_api_target_group.arn
  }
}

resource "aws_lb_target_group" "k8s_api_target_group" {
  name        = "k8s-api-server"
  port        = 6443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  health_check {
    protocol = "HTTPS"
    port     = "traffic-port"
    path     = "/readyz"
    matcher  = "200"
  }
}

resource "aws_lb_target_group_attachment" "control_plane" {
  for_each = local.control_plane_nodes

  target_group_arn = aws_lb_target_group.k8s_api_target_group.arn
  target_id        = each.value.id
  port             = 6443
}