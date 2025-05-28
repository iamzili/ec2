
# Centralized user data script
locals {
  user_data_common = templatefile("${path.module}/user_data_common", {})
  user_data_client = templatefile("${path.module}/user_data_client", {})
  user_data_server = templatefile("${path.module}/user_data_server", {})
}

# IAM Role for SSM
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cwagent_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Security Groups
resource "aws_security_group" "instance_1_sg" {
  name        = "instance-1-sg-zili"
  description = "Security group for instance 1"
  vpc_id      = aws_vpc.main.id

  tags = {
    Owner = "zili"
  }
}

resource "aws_security_group" "instance_2_sg" {
  name        = "instance-2-sg-zili"
  description = "Security group for instance 2"
  vpc_id      = aws_vpc.main.id

  tags = {
    Owner = "zili"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_1" {
  security_group_id = aws_security_group.instance_1_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6_1" {
  security_group_id = aws_security_group.instance_1_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_2" {
  security_group_id = aws_security_group.instance_2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6_2" {
  security_group_id = aws_security_group.instance_2_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_icmp_1" {
  security_group_id = aws_security_group.instance_1_sg.id
  ip_protocol       = "icmp"
  from_port         = -1  # All ICMP types
  to_port           = -1  # All ICMP codes
  cidr_ipv4         = "10.0.0.0/16"
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_icmp_2" {
  security_group_id = aws_security_group.instance_2_sg.id
  ip_protocol       = "icmp"
  from_port         = -1  # All ICMP types
  to_port           = -1  # All ICMP codes
  cidr_ipv4         = "10.0.0.0/16"
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_5002_1" {
  security_group_id = aws_security_group.instance_1_sg.id
  ip_protocol       = -1
  from_port         = 5002
  to_port           = 5002
  cidr_ipv4         = "10.0.0.0/16"
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_5002_2" {
  security_group_id = aws_security_group.instance_2_sg.id
  ip_protocol       = -1
  from_port         = 5002
  to_port           = 5002
  cidr_ipv4         = "10.0.0.0/16"
}

# EC2 Instances
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "instance_1" {
  ami                  = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type        = "t3.large"
  subnet_id            = aws_subnet.private_1.id
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.instance_1_sg.id]
  user_data     = "${local.user_data_common}\n${local.user_data_client}"
  monitoring = true # To enable detailed monitoring when launching an instance
  depends_on = [aws_internet_gateway.igw, aws_nat_gateway.nat]


  tags = {
    Name = "client"
    Owner = "zili"
  }
}

resource "aws_instance" "instance_2" {
  ami                  = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type        = "c5a.8xlarge"
  subnet_id            = aws_subnet.private_2.id
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.instance_2_sg.id]
  user_data     = "${local.user_data_common}\n${local.user_data_server}"
  monitoring = true # To enable detailed monitoring when launching an instance
  depends_on = [aws_internet_gateway.igw, aws_nat_gateway.nat]

  tags = {
    Name = "server"
    Owner = "zili"
  }
}

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value = [
    aws_instance.instance_1.id,
    aws_instance.instance_2.id
  ]
}
