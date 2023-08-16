data "aws_region" "this_region_01" {
  provider = aws
}

data "aws_caller_identity" "this_region_01" {
  provider = aws
}

data "aws_region" "this_region_02" {
  provider = aws.region2
}

data "aws_caller_identity" "this_region_02" {
  provider = aws.region2
}
