# SimpleTimeService

This Repository is for Python app  devlopment which returns ip address of the visitor and timestamp.
app runs on port 5000.
App is deployed on AWS Infrastructure.

Infrastructure details.

1.Vm with minimum requirements. t2.micro with Ubuntu OS.
2.  VPC with two public subnets  and one private subnet.
3.App server is hosted in Private subnet and load balancer is hosted in public subnet.
4.Nat gateway is attached to Public subnet for internet accessibility.
5. two Security groups created for App and load balacner. app side we have allowed 5000 and from load balancer side we have allowed 80 port.
6.  AmazonSSMManagedInstanceCore iam role is created and attached to ec2 instance for any remote command execution since the instance is in private subnet without internet access
7.dns_hostname and dns_host_resolution is enabled in vpc for docker image pull and internet connectvity in nat gateway.
8.Github Actions is used for CI/CD pipeline and docker image is pushed to docker hub public.
9.Terraform is used for creating AWS resources.
10. While creating ec2 instance docker installation, image pulling and docker container run commands are given in userdata.
11.Load balancer is created with two sublic subnets and ec2 instance is attached as target group.
12. load balancer listents to port 80. 
docker image
docker pull karthikeyudu/simpletimeservice:20

<img width="759" height="162" alt="image" src="https://github.com/user-attachments/assets/2a803a38-fcfe-4712-bb80-f6706ceeb15f" />

Following  resouces will be created during this deployment.
1.ec2 instance
2.vpc+3subnets+route table 2 +internet gateway
3.security groups 2 for both app and load balancer
4.nat gateway
5. iam role for ec2
6. load balancer with target groups

Following commands are used for deployment of above application and Infrastructure.
terraform plan
terraform apply
terraform destroy is used for killing aws resources.

application overview

        👤 User (Internet)
                |
                v
        🌍 Application Load Balancer (Public Subnets)
                |
                v
        🔒 EC2 Instance (Private Subnet)
                |
                v
        🐳 Docker Container (Port 5000)
                |
                v
        📦 Python App (IP + Timestamp)

------------------- Outbound -------------------

        🔒 EC2 (Private)
                |
                v
        🚪 NAT Gateway (Public Subnet)
                |
                v
        🌐 Internet (Docker Hub / Updates / SSM)


