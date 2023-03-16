# create security group for the application load balancer
resource "aws_security_group" "alb_security_group" {
    name          =  "${var.project_name}-${var.environment}-alb-sg"
    description   = "enable http/https access on port 80/443"
    vpc_id        =     aws_vpc.vpc.id
#inbound rule is called ingress
  ingress{
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress{
    description = "https access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# outbound traffic is called egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags     = {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
}

# create security group for the bastion host aka jump box
resource "aws_security_group" "bastion_security_group" {
    name          =  "${var.project_name}-${var.environment}-bastion-sg"
    description   = "enable ssh access on port 22"
    vpc_id        = aws_vpc.vpc.id

     ingress{
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_location] # using a variable to limit traffic (ip's)that can ssh into our EC2 intsance to our ip address
  }

   egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags     = {
      Name = "${var.project_name}-${var.environment}-bastion-sg"
    }
}

# create security group for the app server
resource "aws_security_group" "app_server_security_group" {
    name               = "${var.project_name}-${var.environment}-app-server-sg"
    description        =  "enable http/https access on port 80/443 via alb sg"
    vpc_id             = aws_vpc.vpc.id

  ingress {
    description = "https access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  ingress {
    description          = "https access"
    from_port            = 443
    to_port              = 443
    protocol             = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
}

 tags     = {
      Name = "${var.project_name}-${var.environment}-app-server-sg"
    }
}

# create security group for the database
resource "aws_security_group" "database_security_group" {
      name             = "${var.project_name}-${var.environment}-database-sg"
    description        =  "enable mysql/aurora access on port 3306"
    vpc_id             =  aws_vpc.vpc.id

  ingress {
    description = "mysql/aurora access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app_server_security_group.id]
  }
# allow traffic from 3306 only if the traffic coming from the bastion host sg.the reason for this sg to the rds sg is for when we migrate data into the rds data base
  ingress {
    description          = "custom access" 
    from_port            =    3306                   
    to_port              = 3306
    protocol             = "tcp"
    security_groups = [aws_security_group.bastion_security_group.id]
  }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
}

 tags     = {
      Name =  "${var.project_name}-${var.environment}-database-sg"
    }
}