terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider #

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region     = "${var.region}"
}

# Create VPC #

resource "aws_vpc" "MFP_VPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Assignment_VPC"
  }

}

# Create Public Subnet #

resource "aws_subnet" "Public_Subnet_Web1" {
  vpc_id     = aws_vpc.MFP_VPC.id
  cidr_block = "10.0.0.16/28"
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Public_Subnet_Web1"
  }
}

resource "aws_subnet" "Public_Subnet_Web2" {
  vpc_id     = aws_vpc.MFP_VPC.id
  cidr_block = "10.0.0.32/28"
  availability_zone = "ap-southeast-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Public_Subnet_Web2"
  }
}

# Create Internet Gateway [IGW] #

resource "aws_internet_gateway" "Internet_Gateway" {
  vpc_id = aws_vpc.MFP_VPC.id

  tags = {
    Name = "IGW_Assignment_VPC"
  }
}

# Create EIP

resource "aws_eip" "nat_gateway1" {
  vpc = true
}

# Create NAT Gateway #

resource "aws_nat_gateway" "Nat_Gateway1" {
#  connectivity_type = "private"
  allocation_id     = aws_eip.nat_gateway1.id
  subnet_id         = aws_subnet.Public_Subnet_Web1.id

  tags = {
    Name = "NAT_Gateway1_Assignment_VPC"
  }

}

output "nat_gateway_ip1" {
  value = aws_eip.nat_gateway1.public_ip
}

# Create EIP

resource "aws_eip" "nat_gateway" {
  vpc = true
}

# Create NAT Gateway #

resource "aws_nat_gateway" "Nat_Gateway2" {
#  connectivity_type = "private"
  allocation_id     = aws_eip.nat_gateway.id
  subnet_id         = aws_subnet.Public_Subnet_Web2.id

  tags = {
    Name = "NAT_Gateway2_Assignment_VPC"
  }

}

output "nat_gateway_ip" {
  value = aws_eip.nat_gateway.public_ip
}

# Create Security Group for Public Web Subnet #

resource "aws_security_group" "Allow_Web_Traffic" {
  name        = "allow_web_ssh_traffic"
  description = "Allow inbound 22,80,443"
  vpc_id      = aws_vpc.MFP_VPC.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow_Web_SSH_Access"
  }
}

# Route Table Routes #

resource "aws_route_table" "Route_Table" {

  vpc_id = aws_vpc.MFP_VPC.id

  tags = {
      Name = "Public-RT"
  }
}

resource "aws_route" "public" {
  
  route_table_id = aws_route_table.Route_Table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.Internet_Gateway.id
}

resource "aws_route_table_association" "public1" {
  route_table_id = aws_route_table.Route_Table.id
  subnet_id = aws_subnet.Public_Subnet_Web1.id
}

resource "aws_route_table_association" "public2" {
  subnet_id = aws_subnet.Public_Subnet_Web2.id
  route_table_id = aws_route_table.Route_Table.id
}



##############  Application Tier ############

# Create Private Subnet #

resource "aws_subnet" "Private_Subnet_App1" {
  vpc_id     = aws_vpc.MFP_VPC.id
  cidr_block = "10.0.0.48/28"
  availability_zone = "ap-southeast-1b"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "Private_Subnet_App1"
  }
}

resource "aws_subnet" "Private_Subnet_App2" {
  vpc_id     = aws_vpc.MFP_VPC.id
  cidr_block = "10.0.0.64/28"
  availability_zone = "ap-southeast-1b"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "Private_Subnet_App2"
  }
}

# Create Security Group for Private APP subnet #

resource "aws_security_group" "Allow_APP_Traffic" {
  name        = "allow_APP_web_ssh_traffic"
  description = "Allow inbound 22,80,443"
  vpc_id      = aws_vpc.MFP_VPC.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow_APP_Web_SSH_Access"
  }
}

## Create Route Table for Private Subnet

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.MFP_VPC.id
  
  tags = {
      Name = "Private-RT"
  }
}

resource "aws_route" "private1" {
  
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.Nat_Gateway1.id
}

#resource "aws_route" "private2" {
  
#  route_table_id = aws_route_table.private.id
#  destination_cidr_block = "10.0.0.64/28"
#  nat_gateway_id = aws_nat_gateway.Nat_Gateway2.id 
#}

resource "aws_route_table_association" "private1" {
  route_table_id = aws_route_table.private.id
  subnet_id = aws_subnet.Private_Subnet_App2.id
}

resource "aws_route_table_association" "private2" {
  route_table_id = aws_route_table.private.id
  subnet_id = aws_subnet.Private_Subnet_App1.id
}
