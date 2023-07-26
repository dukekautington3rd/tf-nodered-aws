resource "aws_iam_role" "another_flow_role" {
  name = "another_flow_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    yor_trace = "6ba2be4e-676d-4884-a250-7abc15392aa8"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
}

resource "aws_iam_role_policy" "another_flow_policy" {
  name = "another_flow_policy"
  role = aws_iam_role.another_flow_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "ssm_role_tf" {
  name = "ssm_role_tf_${random_string.suffix.id}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
  tags = {
    yor_trace = "b043b8a0-c191-471b-a15a-5b4e404d294d"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
}

resource "aws_iam_role_policy_attachment" "role_attach" {
  role       = aws_iam_role.ssm_role_tf.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_instance_profile" "ssm_mgr_policy" {
  name = "ssm_mgr_tf_${random_string.suffix.id}"
  role = aws_iam_role.ssm_role_tf.name
  tags = {
    yor_trace = "1d93317f-106a-4972-97ca-f418f80c1fc4"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
}