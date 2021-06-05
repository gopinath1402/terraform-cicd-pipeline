resource "aws_vpc" "default" {
  cidr_block           = "10.31.0.0/16"
  enable_dns_hostnames = true
}