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