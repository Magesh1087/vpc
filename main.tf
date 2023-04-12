terraform {
  required_version = ">= 0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  
}
 
provider "aws" {
    region  = "eu-west-1"
    
}

#Creating AWS VPC for Public/Private
resource "aws_vpc" "pubpvt-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
#  instance_tenancy     = var.tenancy

  tags = {
    Name = "${var.network_tag_prefix}-vpc"
  }
}

#Creating 3 public subnets
resource "aws_subnet" "master_sub" {
  count                   = length(var.master_subnet_cidrs)
  vpc_id                  = aws_vpc.pubpvt-vpc.id
  cidr_block              = element(var.master_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.master]   #Need to check

  tags = {
    Name : "Master Subnet ${count.index + 1}"
  }
}

#Creating 3 private subnets
resource "aws_subnet" "worker_sub" {
  count                   = length(var.worker_subnet_cidrs)
  vpc_id                  = aws_vpc.pubpvt-vpc.id
  cidr_block              = element(var.worker_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  #depends_on              = [aws_nat_gateway.nat2]  #Need to check 

  tags = {
    Name : "Worker Subnet ${count.index + 1}"
  }
}

#Creating Internet Gateway 
resource "aws_internet_gateway" "master" {
  vpc_id = aws_vpc.pubpvt-vpc.id

  tags = {
    Name = "Test_InternetGateway"
  }
}

#Creating Master Routetable
resource "aws_route_table" "master_rt" {
  vpc_id = aws_vpc.pubpvt-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.master.id
  }
  tags = {
    Name : "Master Route Table"
  }
}

#Associating subnet to Master Routetable
resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.master_subnet_cidrs)
 subnet_id      = element(aws_subnet.master_sub[*].id, count.index)
 route_table_id = aws_route_table.master_rt.id
}

#Creating Elasticip
resource "aws_eip" "eip" {
  count = 3
  vpc = true
}

#Creating NAT Gateway 
resource "aws_nat_gateway" "nat" {
  count = 3
  allocation_id = element(aws_eip.eip[*].id, count.index)
  subnet_id     = element(aws_subnet.master_sub[*].id, count.index)
  tags = {
    Name : "NAT GW ${count.index + 1}"
  }
}

#Creating 3 Worker Routetable
resource "aws_route_table" "worker_rt" {
    count = 3
  vpc_id = aws_vpc.pubpvt-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = element(aws_nat_gateway.nat[*].id, count.index)
  }
    tags = {
    Name : "Master Route Table ${count.index + 1}"
  }
}

#Associating subnet to Worker Routetable
resource "aws_route_table_association" "private_subnet_asso" {
count = length(var.worker_subnet_cidrs)
 subnet_id      = element(aws_subnet.worker_sub[*].id, count.index)
 route_table_id = element(aws_route_table.worker_rt[*].id, count.index)
}

#Creating Security group
resource "aws_security_group" "openshift-vpc" {
  name        = "Openshift_${var.network_tag_prefix}-SecurityGroup"
  description = "Default security group that allows all instances in the VPC to talk to each other over any port and protocol."
  vpc_id      = aws_vpc.pubpvt-vpc.id
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
}
