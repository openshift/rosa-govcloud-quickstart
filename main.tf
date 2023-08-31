resource "aws_iam_service_linked_role" "elb" {
  count            = var.create_elb_iam_role ? 1 : 0
  aws_service_name = "elasticloadbalancing.amazonaws.com"
}

resource "aws_vpc" "rosa" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_subnet" "rosa_private" {
  for_each          = { for idx, az in local.azs : az => idx }
  availability_zone = each.key
  vpc_id            = aws_vpc.rosa.id
  cidr_block        = cidrsubnet(var.cidr, length(local.azs), each.value)

  tags = {
    Name                              = "${var.name}-private-${each.key}"
    "kubernetes.io/role/internal-elb" = ""
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "rosa_public" {
  for_each          = { for idx, az in local.azs : az => idx }
  availability_zone = each.key
  vpc_id            = aws_vpc.rosa.id
  cidr_block        = cidrsubnet(var.cidr, length(local.azs), length(local.azs) + each.value)

  tags = {
    Name                     = "${var.name}-public-${each.key}"
    "kubernetes.io/role/elb" = ""
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_internet_gateway" "rosa" {
  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_internet_gateway_attachment" "rosa" {
  internet_gateway_id = aws_internet_gateway.rosa.id
  vpc_id              = aws_vpc.rosa.id
}

resource "aws_route_table" "rosa_public" {
  vpc_id = aws_vpc.rosa.id

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table_association" "rosa_public" {
  for_each       = aws_subnet.rosa_public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.rosa_public.id
}

resource "aws_route" "internet_egress" {
  route_table_id         = aws_route_table.rosa_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rosa.id
}

resource "aws_eip" "nat_gw" {
  for_each = aws_subnet.rosa_public

  vpc = true

  tags = {
    Name = "${var.name}-eip-${each.key}"
  }

  // EIP may require IGW to exist prior to association.
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
  depends_on = [aws_internet_gateway_attachment.rosa]
}

resource "aws_nat_gateway" "rosa" {
  for_each          = aws_subnet.rosa_public
  allocation_id     = aws_eip.nat_gw[each.key].allocation_id
  connectivity_type = "public"
  subnet_id         = each.value.id

  tags = {
    Name = "${var.name}-nat-${each.key}"
  }
}

resource "aws_route_table" "rosa_private" {
  for_each = aws_subnet.rosa_private
  vpc_id   = aws_vpc.rosa.id

  tags = {
    Name = "${var.name}-private-${each.key}"
  }
}

resource "aws_route_table_association" "rosa_private" {
  for_each       = aws_subnet.rosa_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.rosa_private[each.key].id
}

resource "aws_route" "nat_gateway" {
  for_each               = aws_subnet.rosa_private
  route_table_id         = aws_route_table.rosa_private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.rosa[each.key].id
}

// Create a jumphost
resource "aws_security_group" "jumphost_sg" {
  name = "${var.name}-jumphost-sg"
  vpc_id = aws_vpc.rosa.id

  tags = {
    Name = "${var.name}-jumphost-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jumphost_sg_ssh" {
  security_group_id = aws_security_group.jumphost_sg.id

  cidr_ipv4 = "0.0.0.0/0"
  to_port = 22
  from_port = 22
  ip_protocol = "tcp"
}

resource "tls_private_key" "jumphost_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jumphost_key_pair" {
  key_name   = "${var.name}-jumphost-key"
  public_key = tls_private_key.jumphost_key.public_key_openssh
}

resource "aws_instance" "jumphost" {
  ami = "ami-04482d061459e6c32"
  instance_type = "t3.micro"
  key_name = aws_key_pair.jumphost_key_pair.key_name
  security_groups = [
    aws_security_group.jumphost_sg.id
  ]
  subnet_id = aws_subnet.rosa_public[data.aws_availability_zones.available.names[0]].id
}