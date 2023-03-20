terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "urotaxi-tfstate-bucket"
    region = "ap-south-1"
    key = "terraform.tfstate"
    dynamodb_table = "urotaxi-terraform-lock"
  }
}

provider "aws" {
    region = "ap-south-1"  
}
resource "aws_vpc" "urotaxivpc" {
    cidr_block = var.urotaxivpc_cidr_block
    tags = {
      "Name" = "urotaxivpc"
    }  
}
resource "aws_subnet" "urotaxipubsn1" {
    vpc_id = aws_vpc.urotaxivpc.id
    cidr_block = var.urotaxipubsn1_cidr_block
    availability_zone = "ap-south-1a"
    tags = {
      "Name" = "urotaxipubsn1"
    }  
}
resource "aws_subnet" "urotaxihybsn2" {
    vpc_id = aws_vpc.urotaxivpc.id
    cidr_block = var.urotaxihybsn2_cidr_block
    availability_zone = "ap-south-1b"
    tags = {
      "Name" = "urotaxihybsn2"
    }  
}
resource "aws_subnet" "urotaxiprvsn3" {
    vpc_id = aws_vpc.urotaxivpc.id
    cidr_block = var.urotaxiprvsn3_cidr_block
    availability_zone = "ap-south-1a"
    tags = {
      "Name" = "urotaxiprvsn3"
    }  
}
resource "aws_subnet" "urotaxiprvsn4" {
    vpc_id = aws_vpc.urotaxivpc.id
    cidr_block = var.urotaxiprvsn4_cidr_block
    availability_zone = "ap-south-1b"
    tags = {
      "Name" = "urotaxiprnsn4"
    }  
}
resource "aws_internet_gateway" "urotaxiigw" {
    vpc_id = aws_vpc.urotaxivpc.id
    tags = {
      "Name" = "urotaxiigw"
    }  
}
resource "aws_route_table" "urotaxiigwrt" {
    vpc_id = aws_vpc.urotaxivpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.urotaxiigw.id
    }
    tags = {
      "Name" = "urotaxiigwrt"
    }  
}
resource "aws_route_table_association" "urotaxirtassociation" {
    route_table_id = aws_route_table.urotaxiigwrt.id
    subnet_id = aws_subnet.urotaxipubsn1.id  
}
resource "aws_eip" "urotaxieip" {
    vpc = true  
}
resource "aws_nat_gateway" "urotaxinatgtw" {
  subnet_id = aws_subnet.urotaxipubsn1.id
  allocation_id = aws_eip.urotaxieip.id
  depends_on = [aws_internet_gateway.urotaxiigw]
  tags = {
    "Name" = "urotaxinatgtw"
  }
}
resource "aws_route_table" "urotaxinatigwrt" {
    vpc_id = aws_vpc.urotaxivpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.urotaxinatgtw.id
    }
    tags = {
      "Name" = "urotaxinatigwrt"
    }  
}
resource "aws_route_table_association" "urotaxinatrtassociation" {
    route_table_id = aws_route_table.urotaxiigwrt.id
    subnet_id = aws_subnet.urotaxihybsn2.id 
}
resource "aws_security_group" "urotaijumpboxsg" {
    vpc_id = aws_vpc.urotaxivpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
        "Name" = "urotaxijumpboxsg"
    }  
}
resource "aws_security_group" "urotaxijavaserversg" {
    vpc_id = aws_vpc.urotaxivpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "10.0.0.0/16" ]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
      "Name" = "urotaxijavaserversg"
    }  
}
resource "aws_security_group" "urotaxidbsg" {
    vpc_id = aws_vpc.urotaxivpc.id
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = [ "10.0.0.0/16" ]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
      "Name" = "urotaxidbsg"
    }  
}
resource "aws_db_subnet_group" "urotaxisubgrp" {
    name = "urotaxisubgrp"
    subnet_ids = [aws_subnet.urotaxiprvsn3.id, aws_subnet.urotaxiprvsn4.id]
    tags = {
      "Name" = "urotaxisubgrp"
    }  
}
resource "aws_db_instance" "urotaxidb" {
    vpc_security_group_ids = [aws_security_group.urotaxidbsg.id]
    allocated_storage = 10
    db_name = "urotaxidb"
    engine = "mysql"
    engine_version = var.db_engine_version
    instance_class = var.db_instance_class
    username = var.db_username
    password = var.db_password
    db_subnet_group_name = aws_db_subnet_group.urotaxisubgrp.name      
}
resource "aws_key_pair" "urotaxikeypair" {
    key_name = "urotaxikeypair"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIRFY7SVsEtoaOSXibJd0rkvizOxyjH6rBRxKtM1Z8yq5/5bo4E7Ss0wMQLXM1Z1J03WQQ906hxSHQaO3STPe/FP9zgdut0qp0P8M4rfFrQJZ1ChnOGcL/4UDBUoKpE8LkchTuYLOLy0ecv0a9VNrEh2IefXlPVGQN599OW6+5BbTojeli6awTpWUAswT8alsm/xzjFXmkDpfEYKMRK3Gp6TATL6nUtfIGkTA+c47qUgAazmEVy81pu6HQLls72o/DtnF08rRmrsEg2LF1VsR0EtWPVlwcdlpC3fvzpso2LsHEoL+KdpZPWc0i07T3fkuTL99P2uy7pzLnLAoMsa7hUqK1Ix502BpEeCn5u0WF0LVngWGPC+H3eCTlqh+y7KoNe11Ez2+9Jb1Q/JofgnsqZE/uA97TSzSNScgKUId/GSWk3FnPgJl+cNVPD34Blva9rO8c3JksRDUcsvE+8tJX6gE+8pnFpxPZudkGaLOtR3WgdoD1lXlUmLlu6wIwE2M= hii@Pavan" 
}
resource "aws_instance" "urotaxiec2" {
    ami = var.ami
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.urotaxijavaserversg.id]
    subnet_id = aws_subnet.urotaxihybsn2.id
    key_name = aws_key_pair.urotaxikeypair.key_name  
}
resource "aws_instance" "urotaxijumpbox" {
    ami = var.ami
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.urotaijumpboxsg.id]
    subnet_id = aws_subnet.urotaxipubsn1.id
    key_name = aws_key_pair.urotaxikeypair.key_name
    associate_public_ip_address = true 
}