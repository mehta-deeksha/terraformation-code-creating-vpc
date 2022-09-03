#Create VPC in us-east-1
resource "aws_vpc" "vpc-master-virginia" {
  provider             = aws.master-region
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-jenkins-m"
    Env  = "test"
  }
}
#Create VPC in us-west-2
resource "aws_vpc" "vpc_master_ohio" {
  provider             = aws.worker-region
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-jenkins-w"
  }
}

#Getting all availability zones
data "aws_availability_zones" "azs" {
  provider = aws.master-region
  state    = "available"

}

#Creating Subnets in us-east1
resource "aws_subnet" "public-subnet1" {
  provider          = aws.master-region
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc-master-virginia.id
  cidr_block        = "10.1.1.0/24"
}

#Creating Subnets in us-east1
resource "aws_subnet" "public-subnet2" {
  provider          = aws.master-region
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc-master-virginia.id
  cidr_block        = "10.1.2.0/24"
}

#Creating Subnets in us-west2
resource "aws_subnet" "subnet-worker" {
  provider   = aws.worker-region
  vpc_id     = aws_vpc.vpc_master_ohio.id
  cidr_block = "192.168.1.0/24"
}

#Creating IGW in us-east1
resource "aws_internet_gateway" "igw_master" {
  provider = aws.master-region
  vpc_id   = aws_vpc.vpc-master-virginia.id
}

#Creating IGW in us-west2
resource "aws_internet_gateway" "igw_worker" {
  provider = aws.worker-region
  vpc_id   = aws_vpc.vpc_master_ohio.id
}


#Initiating VPC peering request from us-east-1 to us-east-2
resource "aws_vpc_peering_connection" "east1-west2" {
  provider    = aws.master-region
  vpc_id      = aws_vpc.vpc-master-virginia.id
  peer_vpc_id = aws_vpc.vpc_master_ohio.id
  peer_region = var.region-jenkins-worker
}

#Accepting peerconnection request on us-west2
resource "aws_vpc_peering_connection_accepter" "accept-peer-connection" {
  provider                  = aws.worker-region
  vpc_peering_connection_id = aws_vpc_peering_connection.east1-west2.id
  auto_accept               = true
}

#creating RouteTable Entries

resource "aws_route_table" "my_route_table" {
  provider = aws.master-region
  vpc_id   = aws_vpc.vpc-master-virginia.id
  route {
    gateway_id = aws_internet_gateway.igw_master.id
    cidr_block = "0.0.0.0/0"
  }

  route {
    vpc_peering_connection_id = aws_vpc_peering_connection.east1-west2.id
    cidr_block                = "192.168.1.0/24"
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

#Overwrite default route table of VPC(Master) with our route table entries
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.master-region
  vpc_id         = aws_vpc.vpc-master-virginia.id
  route_table_id = aws_route_table.my_route_table.id
}


#creating RouteTable Entries

resource "aws_route_table" "worker_route_table" {
  provider = aws.worker-region
  vpc_id   = aws_vpc.vpc_master_ohio.id
  route {
    gateway_id = aws_internet_gateway.igw_worker.id
    cidr_block = "0.0.0.0/0"
  }

  route {
    vpc_peering_connection_id = aws_vpc_peering_connection.east1-west2.id
    cidr_block                = "10.1.1.0/24"
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
  }
}

#Overwrite default route table of VPC(Worker) with our route table entries
resource "aws_main_route_table_association" "set-worker-default-rt-assoc" {
  provider       = aws.worker-region
  vpc_id         = aws_vpc.vpc_master_ohio.id
  route_table_id = aws_route_table.worker_route_table.id
}