# Advanced File Organization Patterns

## Environment-Specific Structure

environments/
├── dev/
│   ├── backend.tf
│   ├── terraform.tfvars
│   └── main.tf
├── staging/
│   ├── backend.tf
│   ├── terraform.tfvars
│   └── main.tf
└── production/
    ├── backend.tf
    ├── terraform.tfvars
    └── main.tf

modules/
├── vpc/
├── security/
└── compute/

shared/
├── variables.tf
├── outputs.tf
└── locals.tf

## Service-Based Structure
infrastructure/
├── networking/
│   ├── vpc.tf
│   ├── subnets.tf
│   └── routing.tf
├── security/
│   ├── security-groups.tf
│   ├── nacls.tf
│   └── iam.tf
├── compute/
│   ├── ec2.tf
│   ├── autoscaling.tf
│   └── load-balancers.tf
├── storage/
│   ├── s3.tf
│   ├── ebs.tf
│   └── efs.tf
└── data/
    ├── rds.tf
    ├── dynamodb.tf
    └── elasticache.tf
