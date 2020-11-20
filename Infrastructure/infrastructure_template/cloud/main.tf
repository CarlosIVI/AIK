provider "aws" {
  region = "us-east-2"
}

#VPC

resource "aws_vpc" "aik_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "aik-est10-vpc"
  }
}

#IGW
resource "aws_internet_gateway" "aik-igw" {
  vpc_id = aws_vpc.aik_vpc.id
}

resource "aws_eip" "nat-eip" {
  vpc = true

  tags = {
    Name = "IP for NAT gateway"
  }
}

resource "aws_nat_gateway" "aik-nat" {

  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.aik-subnet-public1-est10.id
  depends_on    = [aws_internet_gateway.aik-igw]
}


#CRREATE PUBLIC ROUTE TABLE

resource "aws_route_table" "rtb-public" {
  vpc_id = aws_vpc.aik_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aik-igw.id
  }

  tags = {
    Name = "aik-est10-publicrtb"
  }
}

#Create and associate public subnets with a route table

resource "aws_subnet" "aik-subnet-public1-est10" {

  vpc_id                  = aws_vpc.aik_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 4)
  availability_zone       = element(split(",", var.aws_availability_zones), 0)
  map_public_ip_on_launch = true

  tags = {
    Name = "aik-est10-subPublic1"
  }

}

resource "aws_subnet" "aik-subnet-public2-est10" {
  vpc_id                  = aws_vpc.aik_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 5)
  availability_zone       = element(split(",", var.aws_availability_zones), 1)
  map_public_ip_on_launch = true

  tags = {
    Name = "aik-est10-subPublic2"
  }
}

  
 
 resource "aws_route_table" "rtb-private-est10" {

  vpc_id = aws_vpc.aik_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.aik-nat.id
  }

  tags = {
    Name = "PrivateRoute"
  }
}
  
  
resource "aws_subnet" "aik-subnet-private-est10"{

  vpc_id            = aws_vpc.aik_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 6)
  availability_zone = element(split(",", var.aws_availability_zones), 2)

  tags = {
    Name = "aiki-est10-private"
  }
}

resource "aws_subnet" "aik-subnet-private2-est10" {

  vpc_id            = aws_vpc.aik_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 7)
  availability_zone = element(split(",", var.aws_availability_zones), 1)

  tags = {
    Name = "aik-est10-private2"
  }
}
  
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.aik-subnet-private-est10.id
  route_table_id = aws_route_table.rtb-private-est10.id
}
  
  
resource "aws_db_subnet_group" "aik-subnet-group-db-est10" {
  name       = "dbsbunetgroup"
  subnet_ids = [aws_subnet.aik-subnet-private2-est10.id,aws_subnet.aik-subnet-private-est10.id]

  tags = {
    Name = "db-subnet-aik-est10"
  }
}


resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.aik-subnet-public1-est10.id
  route_table_id = aws_route_table.rtb-public.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.aik-subnet-public2-est10.id
  route_table_id = aws_route_table.rtb-public.id
}

resource "aws_security_group" "aik_sg_portal_est10" {

  name        = "frontend"
  description = "Sf for allow traffic to portal frontend"
  vpc_id      = aws_vpc.aik_vpc.id

  ingress {
    from_port   = "3030"
    to_port     = "3030"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
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


resource "aws_autoscaling_group" "aik_autoscaling" {
  launch_configuration = aws_launch_configuration.aik_lcfg.name
  min_size             = 1
  max_size             = 1
  vpc_zone_identifier  = [aws_subnet.aik-subnet-public1-est10.id, aws_subnet.aik-subnet-public2-est10.id]
  health_check_grace_period = 300
  health_check_type         = "EC2"
  target_group_arns         = ["${aws_lb_target_group.asg_est10.arn}"]

  tag {
    key                 = "Name"
    value               = "aik-est10-asg"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "aik_lcfg" {
  name            = "placeholderEst10"
  image_id        = var.aik_ami_id
  instance_type   = var.aik_instance_type
  security_groups = [aws_security_group.aik_sg_portal_est10.id]
  key_name        = var.aik_key_name
  user_data       = file("../scripts/lc.sh")
}

#Create Application Load Balancer
resource "aws_security_group" "sg_lb_est10" {

  name   = var.alb_security_group_name
  vpc_id = aws_vpc.aik_vpc.id

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "aik_lb_est10" {

  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = [aws_subnet.aik-subnet-public1-est10.id, aws_subnet.aik-subnet-public2-est10.id]
  security_groups    = ["${aws_security_group.sg_lb_est10.id}"]

}

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.aik_lb_est10.arn
  port              = 80
  protocol          = "HTTP"


  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg_est10" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }

  }

  action {
    type             = "forward"
   target_group_arn = aws_lb_target_group.asg_est10.arn
  }

}

resource "aws_lb_target_group" "asg_est10" {

  name     = var.alb_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.aik_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 60
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
}

//  resource "aws_db_instance" "aik_db_est10" {
//    depends_on                = [aws_subnet.aik-subnet-public2-est10] 
//    allocated_storage         = 20
//    identifier                = "aik-rds-est10"
//    name                      = "aikdbest10"
//    storage_type              = "gp2"
//    engine                    = "mysql"
//    engine_version            = "5.7.28"
//    instance_class            = "db.t2.micro"
//    username                  = var.aik_db_username
//    password                  = var.aik_db_password
//    parameter_group_name      = "default.mysql5.7"
//    port                      = 3306
//    publicly_accessible       = false
//    vpc_security_group_ids    = [aws_security_group.aik_sg_portal_est10.id]
//    multi_az                  = false
//    final_snapshot_identifier = "aik-rds-est10"
//    db_subnet_group_name      = aws_db_subnet_group.aik-subnet-group-db-est10.name
// }
