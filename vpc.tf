# declare a VPC
resource "aws_vpc" "utility" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name      = "ec2-vpc-${random_string.suffix.id}"
    yor_trace = "8d2b29a9-6d50-4684-a9c7-f8838adae685"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.utility.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name      = "Public Subnet"
    yor_trace = "09693517-da5e-4e47-aab4-49eacf096e85"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
}

resource "aws_internet_gateway" "utility_igw" {
  vpc_id = aws_vpc.utility.id

  tags = {
    Name      = "utility VPC - Internet Gateway"
    yor_trace = "6a7c7c92-30b1-4354-9017-b2b73052d36f"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
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
    yor_trace = "6eefbe9d-3a50-4f91-a331-5097c5eb7dfc"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
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
    yor_trace = "1943fc9f-40dc-4478-bfb1-0abc1f980c69"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
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
    yor_trace = "ab147666-e9b0-4327-8888-72f8979f4c67"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
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
    yor_trace = "fca56148-33c6-470b-a64a-83b48938a7f4"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
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
    yor_trace = "e3f754b6-3754-4c3e-894b-4a039b601869"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
}