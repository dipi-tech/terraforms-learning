output "vpc_id" {
    value = "${aws_vpc.prod_vpc.id}"
}

output "vpc_cidr_block" {
  value = "${aws_vpc.prod_vpc.cidr_block}"
}

output "public_subnet_1" {
  value = "${aws_subnet.public_subnet1.id}"   
}


output "public_subnet_2" {
  value = "${aws_subnet.public_subnet2.id}"   
}


output "public_subnet_3" {
  value = "${aws_subnet.public_subnet3.id}"   
}

output "private_subnet_1" {
  value = "${aws_subnet.private_subnet1.id}"   
}


output "private_subnet_2" {
  value = "${aws_subnet.private_subnet2.id}"   
}


output "private_subnet_3" {
  value = "${aws_subnet.private_subnet3.id}"   
}

