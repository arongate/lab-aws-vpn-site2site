
# network
resource "aws_vpc" "aws-dc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "aws-dc"
    Env  = "lab"
  }
}

# create aws public subnet
resource "aws_subnet" "aws-dc-private" {
  vpc_id            = aws_vpc.aws-dc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "aws-dc-private"
    Env  = "lab"
  }
}

resource "aws_customer_gateway" "op-dc" {
  bgp_asn    = 65000
  ip_address = aws_instance.open-swan.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "op-dc"
    Env  = "lab"
  }
}

resource "aws_vpn_gateway" "aws-dc" {
  vpc_id = aws_vpc.aws-dc.id
  tags = {
    "Name" = "aws-dc"
    "Env"  = "lab"
  }
}

resource "aws_vpn_connection" "op-aws-dc" {
  vpn_gateway_id      = aws_vpn_gateway.aws-dc.id
  customer_gateway_id = aws_customer_gateway.op-dc.id
  type                = "ipsec.1"
  static_routes_only  = true

  local_ipv4_network_cidr  = aws_vpc.op-dc.cidr_block
  remote_ipv4_network_cidr = aws_vpc.aws-dc.cidr_block
  tags = {
    Name = "op-aws-dc"
    Env  = "lab"
  }
}
# resource "aws_vpn_connection_route" "op-dc" {
#   destination_cidr_block = aws_vpc.op-dc.cidr_block
#   vpn_connection_id      = aws_vpn_connection.op-aws-dc.id
# }

resource "aws_vpn_gateway_route_propagation" "aws-dc" {
  vpn_gateway_id = aws_vpn_gateway.aws-dc.id
  route_table_id = aws_vpc.aws-dc.main_route_table_id
}

# create AWS SG
resource "aws_security_group" "aws-dc" {
  name        = "aws-dc"
  description = "aws-dc"
  vpc_id      = aws_vpc.aws-dc.id

  ingress {
    description      = "Allow SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "Allow ICMP from within VPC"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Authorize Internet access"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "aws-dc"
    Env  = "lab"
  }
}


resource "aws_instance" "aws-dc-instance" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.aws-dc.id]
  source_dest_check           = false
  subnet_id                   = aws_subnet.aws-dc-private.id
  # availability_zone           = "eu-west-3a"

  tags = {
    Name = "aws-dc-instance"
    Env  = "lab"
  }
}

output "aws-dc-instance-ip" {
  value = aws_instance.aws-dc-instance.private_ip
}

