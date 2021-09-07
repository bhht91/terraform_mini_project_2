resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    "Name" = "terraform-vpc"
  }
}

resource "aws_subnet" "my-public-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "terraform-public-subnet"
  }
}

resource "aws_subnet" "my-private-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "terraform-private-subnet"
  }
}

resource "aws_internet_gateway" "my-ig" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "terraform-ig"
  }
}

resource "aws_route_table" "my-public-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-ig.id
  }
  tags = {
    Name = "terraform-public-rt"
  }
}

resource "aws_route_table" "my-private-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nat-gw.id
  }
  tags = {
    Name = "terraform-private-rt"
  }
}

resource "aws_eip" "my_eip" {
  vpc = true
  tags = {
    Name  = var.common_tags
    Owner = "Burhan"
  }
}


resource "aws_nat_gateway" "my-nat-gw" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.my-private-subnet.id
  tags = {
    Name = "terraform-nat-gw"
  }
}

resource "aws_security_group" "dynamic-sg" {
  name   = "devops14-dynamic-sg"
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = var.protocol
    cidr_blocks = var.cidr
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = var.protocol
    cidr_blocks = var.cidr
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = var.protocol
    cidr_blocks = var.cidr
  }
}

data "aws_ami" "amazon_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "terraform2" {
  ami           = data.aws_ami.amazon_ami.id
  instance_type = "t2.micro"
  provisioner "local-exec" {
    command = "echo ${aws_instance.terraform2.public_ip} >> public_ips.txt"
  }
  tags = {
    Name = "terraform2"
  }
}

resource "aws_instance" "terraform" {
  ami                         = data.aws_ami.amazon_ami.id
  instance_type               = lookup(var.instance_type, var.region)
  key_name = aws_key_pair.my-key.id
  vpc_security_group_ids      = [aws_security_group.dynamic-sg.id]
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.my-public-subnet.id
  tags = {
    "Name"  = "terraform"
    "Owner" = "burhan"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",
      "cd /var/www/html",
      "sudo wget https://devops14-mini-project.s3.amazonaws.com/default/index-default.html",
      "sudo wget https://devops14-mini-project.s3.amazonaws.com/default/mycar.jpeg",
      "sudo mv index-default.html index.html",
      "sudo systemctl restart httpd"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./private_key.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_key_pair" "my-key" {
  key_name   = "private_key"
  public_key = file("${path.module}/my_public_key.txt")
}

resource "aws_route_table_association" "public-association" {
  subnet_id      = aws_subnet.my-public-subnet.id
  route_table_id = aws_route_table.my-public-rt.id
}

resource "aws_route_table_association" "private-association" {
  subnet_id      = aws_subnet.my-private-subnet.id
  route_table_id = aws_route_table.my-private-rt.id
}

locals {
  time = formatdate("DD MM YYYY hh:mm ZZZ", timestamp())
}

output "timestamp" {
  value = local.time
}