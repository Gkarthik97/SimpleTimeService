provider "aws" {
  region = "us-east-1"
}

# ---------------- VPC ----------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# ---------------- Internet Gateway ----------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# ---------------- PUBLIC SUBNET (ALB) ----------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# ---------------- PRIVATE SUBNET (EC2) ----------------
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}

# ---------------- PUBLIC ROUTE TABLE ----------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------- SECURITY GROUP (ALB) ----------------
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

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
}

# ---------------- SECURITY GROUP (APP) ----------------
resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- EC2 (PRIVATE SUBNET) ----------------
resource "aws_instance" "app" {
  ami           = "ami-0ec10929233384c7f"
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1

              apt update -y
              apt install -y docker.io

              systemctl start docker
              systemctl enable docker

              EOF

  tags = {
    Name = "app-server"
  }
}

# ---------------- TARGET GROUP ----------------
resource "aws_lb_target_group" "tg" {
  name     = "app-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
    port = "5000"
  }
}

# ---------------- TARGET ATTACHMENT ----------------
resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.app.id
  port             = 5000
}

# ---------------- APPLICATION LOAD BALANCER ----------------
resource "aws_lb" "alb" {
  name               = "app-alb"
  load_balancer_type = "application"
  internal           = false

  subnets         = [aws_subnet.public.id]
  security_groups = [aws_security_group.alb_sg.id]
}

# ---------------- LISTENER ----------------
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ---------------- OUTPUT ----------------
output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "private_instance_id" {
  value = aws_instance.app.id
}
