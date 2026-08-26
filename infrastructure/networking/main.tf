data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "cluster" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "cluster" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.cluster.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    Tier = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Session Manager requires no inbound traffic. Kubernetes traffic will later be
# allowed only between members of this security group in a narrowly scoped rule.
resource "aws_security_group" "nodes" {
  name_prefix = "${var.project_name}-nodes-"
  description = "Kubernetes nodes: no internet ingress; outbound access for bootstrapping and SSM"
  vpc_id      = aws_vpc.cluster.id

  egress {
    description = "Temporary learning-cluster egress for package, image, and SSM downloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from within VPC"

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-nodes-sg"
  }
}
