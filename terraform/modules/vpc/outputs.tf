output "output_details" {
  description = "Details of network resources created."
  value = {
    id                   = aws_vpc.vpc.id
    cidr_block           = aws_vpc.vpc.cidr_block
    public_subnet_id     = aws_subnet.public_subnet[*].id
    private_subnet_id    = aws_subnet.private_subnet[*].id
    private_subnet_cidrs = aws_subnet.private_subnet[*].cidr_block
    nat_public_ips       = aws_eip.nat_eip[*].public_ip
    availability_zones   = local.azs
    vpc_region           = aws_vpc.vpc.region
  }
}
