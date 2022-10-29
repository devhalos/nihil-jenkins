# Notes

## Steps to deploy Scalable Jenkins to ECS

### VPC

Prefer to create a separate VPC for the deployment. Do not use the default VPC

Assign IPv4 CIDR

- 10.0.0.0/16

<br/>

### Create Subnets

Prefer creating at minimum, for each AZ. 

- 1 Private Subnet
- 1 Public Subnet

Prefer minimum of 2 AZ

Add identifier such as *private* and *public* to the subnet names to easily identify their use case

Given 2 AZ, You would have 4 subnets with IPv4 CIDRs:

AZ 1
- <common-identifier>-public-1 10.0.0.0/24
- <common-identifier>-private-1 10.0.2.0/24
  
AZ 2
- <common-identifier>-public-2 10.0.1.0/24
- <common-identifier>-private-2 10.0.3.0/24

<br/>

### Create Internet Gateway

Internet gateway is needed to allow traffic from internet to the application in the private subnets.

If a subnet is associated with a route table that has a route to an internet gateway, it's known as a public subnet

If a subnet is associated with a route table that does not have a route to an internet gateway, it's known as a private subnet.

<br/>

#### Create Nat Gateways

NAT gateway is needed to allow traffic from the applications in the private subnets to the internet

Create one for each public subnet created

<br/>

### Create Route Tables

Create one route tables for the public subnets. Route 0.0.0.0/0 to the internet gateway created

Create one for each private subnet. Route 0.0.0.0/0 to the NAT gateway created in the public subnet in the same AZ

<br/>

### Create Security Groups

- One for the load balancer
    - with inbound 80 and 8080 to 0.0.0.0/0
- One for the ecs tasks
    - with inbound 8080 and 50000 to 0.0.0.0/0
- One for the efs
    - with inbound 2049 to sg group created for ecs tasks
- One for ecr endpoints
    - with inbound 443 to 0.0.0.0/0
- One for logs endpoints
    - with inbound 443 to 0.0.0.0/0

<br/>

### Create Endpoints

Endpoints are needed to access aws resources from private subnets without exposing them to the internet

- s3 - gateway => connect to routing table for private subnets
- ecr - api => connect to private subnets and assign ecr security groups
- ecr - dkr => connect to private subnets and assign ecr security groups
- cloudwatch - logs => connect to private subnets and assign cloudwatch security groups

<br/>
    
### Create Load Balancer

Create an ALB to for the jenkins dashboard. The DNS name can also be use as jenkins url. It should be in all public subnets created

Add listeners for port 80

<br/>

#### Create Target Groups

Create target group for load balancer listeners for port 8080

- Target Type: IP

Health Checks

- Protocol: HTTP
- Path: /login
- Healthy Threshold: 5
- Unhealth Threshold: 2
- Timeout: 5
- Interval: 30
- Success Code: 200


<br/>

### EFS

Create a file system in EFS to be use for jenkins master as volume

#### Create access point

- root directory path = /
- posix user id = 0
- posix group id = 0
- root directory owner user id = 1000 => jenkins user
- root directory owner group id = 1000 => jenkins group
- root directory permissions = 755 
- attach to private subnets

<br/>

### Cloud Map

Create namespace to enable service discovery between the jenkins master and agents
- Instance Discovery: API calls and DNS queries in VPCs

Create service with dns configuration:
- Discoverable by: API Calls and DNS Queries
- DNS Routing Policy: Multivalue answer routing
  - A record with TTL=<10 or any value>
  - SRV record with port=50000 and TTL=<10 or any value>

The DNS can be use as the value for the ecs task tunnel in jenkins cloud ecs configuration with the ff. format: <namespace-name>.<service-name>:50000

<br/>

### ECR

Create repository to upload the jenkins image.\
The instruction on how to push **the** images to the repository will be provided when you view the repository details.

<br/>

### Cloudwatch Logs

Create the log group you will specify in ecs agent environment variable: JENKINS_ECS_AWSLOGS_GROUP

<br/>

### IAM

Create roles for ecs tasks

#### Task Role

##### Policy 

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Resource": "arn:aws:elasticfilesystem:{region}:{account-id}:file-system/{efs-id}",
            "Effect": "Allow"
        }
    ]
}
```

##### Trust Relationship 

```json
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### Task Execution Role

##### Policy
- AmazonECSTaskExecutionRolePolicy

##### Trust Relationship

```json
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### Jenkins Agent Role

##### Policy

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecs:DeregisterTaskDefinition",
                "ecs:RegisterTaskDefinition",
                "ecs:DescribeTaskDefinition",
                "ecs:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "ecs:RunTask",
                "ecs:StopTask",
                "ecs:DescribeTasks",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:ecs:*:<account-id>:task/*/*",
                "arn:aws:ecs:*:<account-id>:task-definition/*:*",
                "arn:aws:logs:ap-southeast-1:<account-id>:log-group:/ecs/nihil-jenkins-task:log-stream:*",
                "arn:aws:iam::<account-id>:role/nihil-jenkins-ecs-task-execution-role"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:CreateLogGroup"
            ],
            "Resource": "arn:aws:logs:*:<account-id>:log-group:*"
        }
    ]
}
```

##### Trust Policy

<br/>

#### Jenkins User

Create jenkins user
Save the access key and secret key of the user
It will be used as environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in the jenkins agent config

<br/>

### ECS

#### Task Definition


- Launch Type: Fargate
- Task Memory: 1024
- Task CPU: 512
- Volumes:
  - Volume Type: EFS
  - Root Directory: /
  - Encryption in Transit: Enabled
  - EFS IAM authorization: Enabled
- Container:
  - 8080:8080
  - MountPoint
    - Container Path: /var/jenkins_home
    - Source Volume: <EFS Volume>
  - Log
    - Log Driver: awslogs
    - Log Options: awslogs-group, awslogs-region, awslogs-stream-prefix

#### Service

- Launch Type: Fargate
- Auto-assign public IP: Enabled
- Min Health Percent: 0
- Max Health Percent: 100
- Health Check Grace Period: 300
- Load Balancing
  - name: the load balancer created earlier
  - target group: the target group created earlier
- Force New Deployment
