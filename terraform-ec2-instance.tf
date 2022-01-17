terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.52"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  access_key = "{}"
  secret_key = "{}"
  region     = "ap-south-1"
}

resource "aws_instance" "ec2" {
  ami                    = "ami-0f1fb91a596abf28d"
  instance_type          = "t2.micro"
  key_name               = "firstEC2Instance"
  vpc_security_group_ids = ["${aws_security_group.httpd.id}"]

  tags = {
    Name = "myNewEC2ForDocker"
  }
}

resource "null_resource" "copy_execute" {

  connection {
    type        = "ssh"
    host        = aws_instance.ec2.public_ip
    user        = "ec2-user"
    private_key = file("firstEC2Instance.pem")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum-config-manager --enable rhui-REGION-rhel-server-extras",
      "sudo yum -y install docker",
      "sudo systemctl start docker",
      "sudo docker login -u {username} -p {password}",
      "sudo docker pull {imagename}",
	  "sudo docker run -it -p 8080:80 --name {container_name} {imagename}",
    ]
  }

  depends_on = [aws_instance.ec2]

}

resource "aws_security_group" "httpd" {
  name        = "httpd"
  description = "Allow ssh  inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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