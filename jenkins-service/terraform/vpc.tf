data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "jenkins" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = local.component_name
  }
}

# subnets

resource "aws_subnet" "jenkins_pub" {
  for_each = toset(local.public_subnets)

  vpc_id            = aws_vpc.jenkins.id
  cidr_block        = each.key
  availability_zone = data.aws_availability_zones.available.names[index(local.public_subnets, each.key)]
  tags = {
    Name = "${local.component_name}-pub-${index(local.public_subnets, each.key)}"
  }
}

resource "aws_subnet" "jenkins_pri" {
  for_each = toset(local.private_subnets)

  vpc_id            = aws_vpc.jenkins.id
  cidr_block        = each.key
  availability_zone = data.aws_availability_zones.available.names[index(local.private_subnets, each.key)]
  tags = {
    Name = "${local.component_name}-pri-${index(local.private_subnets, each.key)}"
  }
}

# gateways

resource "aws_internet_gateway" "jenkins" {
  vpc_id = aws_vpc.jenkins.id
  tags = {
    Name = local.component_name
  }
}

resource "aws_eip" "jenkins" {
  for_each = toset(local.public_subnets)
  tags = {
    Name = "${local.component_name}-${index(local.public_subnets, each.key)}"
  }
}

resource "aws_nat_gateway" "jenkins" {
  for_each = toset(local.public_subnets)

  subnet_id     = aws_subnet.jenkins_pub[each.key].id
  allocation_id = aws_eip.jenkins[each.key].id
  tags = {
    Name = "${local.component_name}-${index(local.public_subnets, each.key)}"
  }
}

# route tables

resource "aws_route_table" "jenkins_ig" {
  vpc_id = aws_vpc.jenkins.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins.id
  }

  tags = {
    Name = "${local.component_name}-ig"
  }
}

resource "aws_route_table_association" "jenkins_ig_assoc" {
  for_each = aws_subnet.jenkins_pub

  subnet_id      = each.value.id
  route_table_id = aws_route_table.jenkins_ig.id
}

resource "aws_route_table" "jenkins_nat" {
  for_each = toset(local.private_subnets)

  vpc_id = aws_vpc.jenkins.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.jenkins[local.public_subnets[index(local.private_subnets, each.key)]].id
  }

  tags = {
    Name = "${local.component_name}-nat-${index(local.private_subnets, each.key)}"
  }
}

resource "aws_route_table_association" "jenkins_nat_assoc" {
  for_each = aws_subnet.jenkins_pri

  subnet_id      = each.value.id
  route_table_id = aws_route_table.jenkins_nat[each.key].id
}

# security groups

resource "aws_security_group" "alb" {
  name        = "${local.component_name}-load-balancer"
  description = "allow inbound traffic to load balancer"
  vpc_id      = aws_vpc.jenkins.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "ecs" {
  name        = "${local.component_name}-ecs"
  description = "allow inbound traffic to ecs"
  vpc_id      = aws_vpc.jenkins.id

  ingress {
    from_port   = local.port
    to_port     = local.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = local.tunnel_port
    to_port     = local.tunnel_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "efs" {
  name        = "${local.component_name}-efs"
  description = "allow inbound traffic to ecs"
  vpc_id      = aws_vpc.jenkins.id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    security_groups = [
      aws_security_group.ecs.id
    ]
  }
}
