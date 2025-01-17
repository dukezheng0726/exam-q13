#kms
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "q13-kms" {
  description             = "An example symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/terraform"
        },
        Action = [
          "kms:ReplicateKey",
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/terraform"
        },
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        Resource = "*"
      }
    ]
  })
}


#s3
resource "aws_s3_bucket" "q13-s3" {
  bucket = var.bucket_name
  tags = {
    Name        = "q13-s3"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "q13-s3-version" {
  bucket = aws_s3_bucket.q13-s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "q13-s3-encry" {
  bucket = aws_s3_bucket.q13-s3.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.q13-kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}



#ec2

resource "aws_instance" "q13-ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.q13_sg.id]
  subnet_id              = aws_subnet.q13-subnet1.id

  tags = {
    Name = "q13-ec2"
  }
}

# security_group

resource "aws_security_group" "q13_sg" {
  name        = "q13-sg"
  description = "Allow HTTP traffic on port 80"
  vpc_id      = aws_vpc.q13-vpc.id
}

resource "aws_security_group_rule" "q13-sg-rule" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.q13_sg.id
}



# vpc
resource "aws_vpc" "q13-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "q13-vpc"
  }
}



# internet gateway
resource "aws_internet_gateway" "q13-igw" {
  vpc_id = aws_vpc.q13-vpc.id

  tags = {
    Name = "q13-igw"
  }
}

# route table
resource "aws_route_table" "q13-rt" {
  vpc_id = aws_vpc.q13-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.q13-igw.id
  }

  tags = {
    Name = "q13-rt"
  }
}


# add 1 subnet to the route table
resource "aws_subnet" "q13-subnet1" {
  vpc_id     = aws_vpc.q13-vpc.id
  cidr_block = var.subnet1_cidr

  tags = {
    Name = "q13-subnet1"
  }
}

resource "aws_route_table_association" "subnet1_association" {
  subnet_id      = aws_subnet.q13-subnet1.id
  route_table_id = aws_route_table.q13-rt.id
}