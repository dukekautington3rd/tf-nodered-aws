resource "aws_instance" "k8s_master" {
  ami                         = "ami-09a41e26df464c548"
  instance_type               = "t2.micro"
  key_name                    = var.key_pair
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_mgr_policy.name

  tags = {
    Name      = "k8s master"
    Defender  = "false"
    yor_trace = "d5dc64de-f608-429c-b3b1-9b86fde8d0df"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
  user_data = "${file("init.sh")}"
}

resource "aws_instance" "k8s_worker_1" {
  ami                         = "ami-09a41e26df464c548"
  instance_type               = "t2.micro"
  key_name                    = var.key_pair
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id, aws_security_group.allow_http.id]

  tags = {
    Name      = "k8s worker"
    Defender  = "false"
    yor_trace = "98cda432-d859-4421-a755-38a8edc916b6"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
  user_data = "${file("init.sh")}"

  root_block_device {
    encrypted = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

output "instances" {
  value       = "ssh admin@${aws_instance.k8s_worker_1.public_dns} \"sudo hostname k8s-worker-1\"\nssh admin@${aws_instance.k8s_master.public_dns} \"sudo hostname k8s-master\""
  description = "ssh details"
}