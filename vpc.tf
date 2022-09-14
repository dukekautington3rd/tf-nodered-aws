# declare a VPC
resource "aws_vpc" "utility" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name      = "ec2-vpc-${random_string.suffix.id}"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.utility.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name      = "Public Subnet"
  }
}

resource "aws_internet_gateway" "utility_igw" {
  vpc_id = aws_vpc.utility.id

  tags = {
    Name      = "utility VPC - Internet Gateway"
  }
}

resource "aws_route_table" "utility_us_east_1a_public" {
  vpc_id = aws_vpc.utility.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.utility_igw.id
  }

  tags = {
    Name      = "Public Subnet Route Table"
  }
}

resource "aws_route_table_association" "utility_us_east_1a_public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.utility_us_east_1a_public.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_sg"
  description = "Allow SSH inbound connections"
  vpc_id      = aws_vpc.utility.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "allow_ssh_sg"
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http_sg"
  description = "Allow HTTP inbound connections"
  vpc_id      = aws_vpc.utility.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "allow_http_sg"
  }
}

resource "aws_security_group" "allow_outbound" {
  name        = "allow_outbound_sg"
  description = "Allow outbound connections"
  vpc_id      = aws_vpc.utility.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "allow_outbound_sg"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.utility.id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }

  tags = {
  }
}