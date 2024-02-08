provider "aws" {
  region = "us-east-2"  # Replace with your desired region
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"  # Replace with your desired CIDR block for the VPC
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "example-vpc"
  }

  
}
# Create private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.0.0/17"  # Replace with your desired CIDR block for the public subnet
  availability_zone = "us-east-2a"   # Replace with your desired availability zone

  tags = {
    Name = "private-subnet"
  }
}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.128.0/17"  # Replace with your desired CIDR block for the public subnet
  availability_zone = "us-east-2b"   # Replace with your desired availability zone
  map_public_ip_on_launch = true  # This enables automatic public IP assignment


  tags = {
    Name = "public-subnet"
  }
}



# Create internet gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}

# Create elastic IP for NAT gateway
resource "aws_eip" "nat" {

}

# Create NAT gateway
resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "example-nat"
  }
}


# Create Route Table for public subnet
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
    tags = {
    Name = "public-route-table"
  }
}
# Create Route Table for private subnet
resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.example.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.example.id
  }
    tags = {
    Name = "private-route-table"
  }
}

# route table association with public subnet
resource "aws_route_table_association" "as_1" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt1.id
}

# route table association with private subnet
resource "aws_route_table_association" "as_2" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.rt2.id
}
#create security group
resource "aws_security_group" "name" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.example.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
      tags = {
    Name = "first-sg"
  }
}

#create ec2 in public subnet

resource "aws_instance" "public_instance" {
  ami             = "ami-0c20d88b0021158c6" # Change to your desired AMI ID
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public.id
  key_name        = "terraform2"
  security_groups = [aws_security_group.name.id]
  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl enable httpd
sudo systemctl start httpd
sudo systemctl status httpd

EOF

  tags = {
    Name = "public_instance"
  }
}
