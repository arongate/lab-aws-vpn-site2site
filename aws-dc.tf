
# network
resource "aws_vpc" "aws-dc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "aws-dc"
    Env  = "lab"
  }
}


resource "aws_security_group" "aws-dc" {
  name        = "aws-dc-sg"
  description = "aws-dc-sg"
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
    cidr_blocks      = [aws_vpc.on-premise-dc.cidr_block]
    # ipv6_cidr_blocks = [aws_vpc.on-premise-dc.ipv6_cidr_block]
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


resource "aws_subnet" "aws-dc-private" {
  vpc_id            = aws_vpc.aws-dc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "aws-dc-private"
    Env  = "lab"
  }
}

resource "aws_customer_gateway" "on-premise-dc" {
  bgp_asn    = 65000
  ip_address = aws_instance.open-swan.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "on-premise-dc-cgw"
    Env  = "lab"
  }
}

resource "aws_vpn_gateway" "on-premise-dc" {
  vpc_id = aws_vpc.aws-dc.id
  tags = {
    "Name" = "on-premise-dc-vgw"
    "Env"  = "lab"
  }
}

resource "aws_vpn_connection" "on-premise-dc" {
  vpn_gateway_id      = aws_vpn_gateway.on-premise-dc.id
  customer_gateway_id = aws_customer_gateway.on-premise-dc.id
  type                = "ipsec.1"
  static_routes_only  = true

  local_ipv4_network_cidr  = aws_vpc.on-premise-dc.cidr_block
  remote_ipv4_network_cidr = aws_vpc.aws-dc.cidr_block
  tags = {
    Name = "on-premise-dc-vpn-connection"
    Env  = "lab"
  }
}
resource "aws_vpn_connection_route" "on-premise-dc" {
  destination_cidr_block = aws_vpc.on-premise-dc.cidr_block
  vpn_connection_id      = aws_vpn_connection.on-premise-dc.id
}

resource "aws_vpn_gateway_route_propagation" "aws-dc" {
  vpn_gateway_id = aws_vpn_gateway.on-premise-dc.id
  route_table_id = aws_vpc.aws-dc.main_route_table_id
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

