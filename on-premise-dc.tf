
resource "aws_vpc" "on-premise-dc" {
  cidr_block = "172.21.0.0/16"
  tags = {
    Name = "On-premise-dc"
    Env  = "lab"
  }
}

resource "aws_security_group" "on-premise-dc" {
  name        = "on-premise-edge-router"
  description = "On premise edge router"
  vpc_id      = aws_vpc.on-premise-dc.id

  ingress {
    description      = "Allow SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "Allow ICMP from within VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.on-premise-dc.cidr_block]
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
    Name = "On-premise-dc"
    Env  = "lab"
  }
}

resource "aws_subnet" "on-premise-dc-public" {
  vpc_id     = aws_vpc.on-premise-dc.id
  cidr_block = "172.21.0.0/24"
  # availability_zone = "eu-west-3a"

  tags = {
    Name = "on-premise-dc-public"
    Env  = "lab"
  }
}

resource "aws_internet_gateway" "on-premise-dc" {
  vpc_id = aws_vpc.on-premise-dc.id

  tags = {
    Name = "on-premise-igw"
    Env  = "lab"
  }
}

# we get ami
data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  owners = [ "amazon" ]
}

resource "aws_instance" "open-swan" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.on-premise-dc.id]
  source_dest_check           = false
  subnet_id                   = aws_subnet.on-premise-dc-public.id
  key_name                    = "default"
  user_data                   = file("${path.module}/userdata.sh")
  # availability_zone           = "eu-west-3a"

  tags = {
    Name = "open-swan"
    Env  = "lab"
  }
}

output "open-swan-public-ip" {
  value = aws_instance.open-swan.public_ip
}

resource "aws_default_route_table" "on-premise-dc" {
  default_route_table_id = aws_vpc.on-premise-dc.default_route_table_id

  route {
    cidr_block  = aws_vpc.aws-dc.cidr_block
    instance_id = aws_instance.open-swan.id
  }
  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.on-premise-dc.id
  }

  tags = {
    Name = "on-premise-dc-to-aws-dc"
    Env  = "lab"
  }
}
