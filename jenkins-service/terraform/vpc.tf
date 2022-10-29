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
    from_port   = 8080
    to_port     = 8080
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
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 50000
    to_port     = 50000
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

resource "aws_security_group" "ecr" {
  name        = "${local.component_name}-ecr"
  description = "allow inbound traffic to ecr"
  vpc_id      = aws_vpc.jenkins.id

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

resource "aws_security_group" "cloudwatch" {
  name        = "${local.component_name}-cloudwatch"
  description = "allow inbound traffic to cloudwatch"
  vpc_id      = aws_vpc.jenkins.id

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

# endpoints

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.jenkins.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "${local.component_name}-s3"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_assoc" {
  for_each = aws_route_table.jenkins_nat

  route_table_id  = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.jenkins.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.ecr.id
  ]
  tags = {
    Name = "${local.component_name}-ecr-api"
  }
}

resource "aws_vpc_endpoint_subnet_association" "ecr_api_assoc" {
  for_each = aws_subnet.jenkins_pri

  subnet_id       = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.ecr_api.id
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.jenkins.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.ecr.id
  ]
  tags = {
    Name = "${local.component_name}-ecr-dkr"
  }
}

resource "aws_vpc_endpoint_subnet_association" "ecr_dkr_assoc" {
  for_each = aws_subnet.jenkins_pri

  subnet_id       = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.ecr_dkr.id
}

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id            = aws_vpc.jenkins.id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.cloudwatch.id
  ]
  tags = {
    Name = "${local.component_name}-cloudwatch"
  }
}

resource "aws_vpc_endpoint_subnet_association" "cloudwatch_assoc" {
  for_each = aws_subnet.jenkins_pri

  subnet_id       = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.cloudwatch.id
}
