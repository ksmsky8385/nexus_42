resource "aws_security_group" "k3s" {
  name        = "k3s-sg"
  description = "Security group for k3s EC2 instance"
  vpc_id      = aws_vpc.frodo.id

  # Warning: opening all TCP ports to the internet is risky in production.
  ingress {
    description = "Allow all TCP from anywhere"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "k3s-sg"
  })
}
