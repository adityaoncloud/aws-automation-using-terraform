

# Virtual Private Cloud

resource "aws_vpc" "auto-1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "auto-vpc"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "auto-gw" {
  vpc_id = aws_vpc.auto-1.id

  tags = {
    Name = "auto-gw"
  }
}

# Custom Route Table

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.auto-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.auto-gw.id
  }

}

resource "aws_subnet" "auto-subnet"{
    vpc_id = aws_vpc.auto-1.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"

}

resource "aws_route_table_association" "rta"{
    subnet_id = aws_subnet.auto-subnet.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_net" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.auto-1.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "auto-sg"
  }
}

resource "aws_network_interface" "auto-nt" {
  subnet_id       = aws_subnet.auto-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_net.id]

}

resource "aws_eip" "auto-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.auto-nt.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.auto-gw]

}

resource "aws_instance" "web-server"{
    ami = "ami-06984ea821ac0a879"
    instance_type="t2.micro"
    key_name = "terra-key"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.auto-nt.id
    }

    user_data = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install apache2-bin -y
sudo systemctl start apache2
sudo bash -c 'echo if you see this msg everything worked fine > /var/www/html/index.html'                
                EOF

    tags = {
        Name = "terra-web-server"
    }
}
