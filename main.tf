terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>4.16.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

#creating my first instance
resource "aws_instance" "web1" {
  ami           = "ami-0d09654d0a20d3ae2"
  instance_type = "t2.micro"
  key_name = var.keypair
  vpc_security_group_ids = var.security_group
  subnet_id = var.subnet[0]
  associate_public_ip_address = true

  tags = {
    Name = "web1"
  }

  provisioner "local-exec" {
    command = "echo ubuntu@${self.public_ip} >> /home/vagrant/ansible/host-inventory"
  }
}

#creating my second instance
resource "aws_instance" "web2" {
  ami           = "ami-0d09654d0a20d3ae2"
  instance_type = "t2.micro"
  key_name = var.keypair
  vpc_security_group_ids = var.security_group
  subnet_id = var.subnet[1]
  associate_public_ip_address = true

  tags = {
    Name = "web2"
  }

  provisioner "local-exec" {
    command = "echo ubuntu@${self.public_ip} >> /home/vagrant/ansible/host-inventory"
  }
}

#creating my third instance
resource "aws_instance" "web3" {
  ami           = "ami-0d09654d0a20d3ae2"
  instance_type = "t2.micro"
  key_name = var.keypair
  vpc_security_group_ids = var.security_group
  subnet_id = var.subnet[2]
  associate_public_ip_address = true

  tags = {
    Name = "web3"
  }

  provisioner "local-exec" {
    command = "echo ubuntu@${self.public_ip} >> /home/vagrant/ansible/host-inventory"
  }
}

#creating my load balancer target group
resource "aws_lb_target_group" "tf-lb-tg" {
  name     = "tf-lb-tg"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id = "vpc-057be8ef7f8346de3"

  tags = {
    Name = "tf-lb-tg"
  }

  #creating its health check
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

#attaching my target group to my instances
resource "aws_lb_target_group_attachment" "tf1" {
  target_group_arn = aws_lb_target_group.tf-lb-tg.arn
  target_id        = "${aws_instance.web1.id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "tf2" {
  target_group_arn = aws_lb_target_group.tf-lb-tg.arn
  target_id        = "${aws_instance.web2.id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "tf3" {
  target_group_arn = aws_lb_target_group.tf-lb-tg.arn
  target_id        = "${aws_instance.web3.id}"
  port             = 80
}

#attaching my target group to my load balancer
resource "aws_lb_listener" "tf-listener" {
  load_balancer_arn = aws_lb.tf-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf-lb-tg.arn
  }

   tags = {
    Name = "tf-listener"
  }
}

#creating a load balancer 
resource "aws_lb" "tf-lb" {
  name               = "tf-lb"
  load_balancer_type = "application"
  internal           = false
  security_groups = var.security_group
  subnets            = [var.subnet[0], var.subnet[1], var.subnet[2]]
  ip_address_type = "ipv4"
  enable_deletion_protection = false

  tags = {
    Name = "tf-lb"
  }
}


locals {
  defaults = ["terraform-test", "zainabakinlawon.me"]
}

resource "aws_route53_zone" "zainabakinlawon" {
  name = local.defaults[1]

  tags = {
    Name = local.defaults[1]
  }
}

resource "aws_route53_record" "terraform-test" {
  zone_id = aws_route53_zone.zainabakinlawon.zone_id
  name    = "${local.defaults[0]}.${local.defaults[1]}"
  type    = "CNAME"
  ttl     = "5"
  records = ["${aws_lb.tf-lb.dns_name}"]
}
