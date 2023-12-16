resource "aws_vpc" "mk_vpc" {
  cidr_block = "10.0.0.0/16" #It is just one of the private IP addresses  

  #These two are false in defualt
  enable_dns_hostnames = true #Instances in the VPC receive public DNS hostnames
  enable_dns_support   = true #Dns resolution = Convert Domain name into IP address

  tags = {
    Name = "MyVPC" # tags for easy identification
  }
}
resource "aws_subnet" "mk_public_subnet" {
  vpc_id                  = aws_vpc.mk_vpc.id
  cidr_block              = "10.0.1.0/24" #Cidr block for subnet. Must be inside of VPC cidr block and dont overlap with vpc cidr block
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    Name = "dev-public"
  }
}
resource "aws_internet_gateway" "mk_ig" {
  vpc_id = aws_vpc.mk_vpc.id
  tags = {
    Name = "dev-ig"
  }
}

resource "aws_route_table" "mk_public_rt" {
  vpc_id = aws_vpc.mk_vpc.id
  tags = {
    Name = "dev-rt"
  }
}
resource "aws_route" "mk_route" {
  route_table_id         = aws_route_table.mk_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mk_ig.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mk_public_subnet.id
  route_table_id = aws_route_table.mk_public_rt.id
}

resource "aws_security_group" "mk_sg" {
  name        = "dev-sg"
  description = "dev-security group"
  vpc_id      = aws_vpc.mk_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["49.224.254.159/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "mk_key"
  public_key = file("~/.ssh/mk_key.pub")

}

resource "aws_instance" "mk_ec2" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.id
  vpc_security_group_ids = [aws_security_group.mk_sg.id]
  subnet_id              = aws_subnet.mk_public_subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 9
  }
  tags = {
    name = "dev-node"
  }
}