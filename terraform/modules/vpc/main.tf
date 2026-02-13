#============================================ Networking Resources ============================================#
# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Local variables for cleaner code
locals {
  az_count = min(2, length(data.aws_availability_zones.available.names))
  azs      = slice(data.aws_availability_zones.available.names, 0, local.az_count)
}

# Create VPC for the service
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "project-${var.project_name}-vpc"
    Project = var.project_tag
  }
}

# Create public subnets for the service
resource "aws_subnet" "public_subnet" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub_cidr_block[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "project-${var.project_name}-pub-subnet-${count.index + 1}"
    Project                                         = var.project_tag
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/project-bedrock-cluster" = "shared"
  }
}

# Create private subnets for the service
resource "aws_subnet" "private_subnet" {
  count             = local.az_count
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.priv_cidr_block[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name                                            = "project-${var.project_name}-private-subnet-${count.index + 1}"
    Project                                         = var.project_tag
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/project-bedrock-cluster" = "shared"
  }
}

# Create internet gateway for the service
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "project-${var.project_name}-ig"
    Project = var.project_tag
  }
}

# Create elastic IPs for NAT Gateways, one per AZ for high availability
resource "aws_eip" "nat_eip" {
  count  = 2
  domain = "vpc"

  tags = {
    Name    = "project-${var.project_name}-eip-${count.index + 1}"
    Project = var.project_tag
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

# Create NAT Gateways for the service
resource "aws_nat_gateway" "nat_gateway" {
  count         = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name    = "project-${var.project_name}-nat-gateway-${count.index + 1}"
    Project = var.project_tag
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

# Create the public route table for the service
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name    = "project-${var.project_name}-public-rt"
    Project = var.project_tag
  }
}

# Associate the public route table with the public subnets
resource "aws_route_table_association" "public_rt_assoc" {
  count          = local.az_count
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Create private route tables, one per AZ for high availability
resource "aws_route_table" "private_rt" {
  count  = 2
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name    = "project-${var.project_name}-private-rt-${count.index + 1}"
    Project = var.project_tag
  }
}

# Associate private route tables with private subnets
resource "aws_route_table_association" "private_rt_assoc" {
  count          = local.az_count
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}
