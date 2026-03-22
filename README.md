# terraform-aws-ha-web-infrastructure

> Highly available, auto-scaling Apache web infrastructure on AWS — built entirely with Terraform.

---

## What This Project Does

This project uses Terraform to deploy a production-grade, highly available web application on AWS. It provisions a custom VPC with public and private subnets across 3 availability zones, an Application Load Balancer, an Auto Scaling Group with CloudWatch-driven scaling policies, and Apache web servers — all from code.

**Deployed and verified working on AWS** — load balancer distributes traffic across EC2 instances in separate availability zones, with both targets confirmed healthy.

---

## Architecture

```
                        Internet
                           |
                   Internet Gateway
                           |
          ┌────────────────┼────────────────┐
          │                │                │
     Public-1a        Public-1b        Public-1c
          │                │                │
          └────────── NAT Gateway ──────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
    Private-1a        Private-1b       Private-1c
          │                │                │
       EC2 (ASG)        EC2 (ASG)       EC2 (ASG)
          │                │                │
          └────────── ALB (Public) ─────────┘
                           │
                        Internet
```

---

## AWS Services Used

- **VPC** — Custom VPC with public and private subnets across 3 AZs
- **EC2** — Apache web servers deployed in private subnets via Auto Scaling Group
- **ALB** — Application Load Balancer distributing HTTP traffic across instances
- **Auto Scaling Group** — Maintains desired capacity, replaces unhealthy instances
- **CloudWatch** — CPU alarms trigger scale-up (>70%) and scale-down (<30%) policies
- **NAT Gateway** — Allows private EC2s to reach the internet without public IPs
- **Security Groups** — ALB accepts port 80 from internet; EC2s only accept traffic from ALB

---

## Key Technical Decisions

**Dynamic subnet calculation using `cidrsubnet()`**
Instead of hardcoding subnet CIDRs, subnets are calculated dynamically from the VPC CIDR block. This makes the configuration reusable across environments without manual IP planning.

**EC2 instances have no public IPs**
All web servers live in private subnets. Traffic only reaches them through the ALB, reducing the attack surface. The `associate_public_ip_address = false` setting in the launch template enforces this.

**Scale-in policy removes one instance at a time**
`scaling_adjustment = -1` prevents aggressive scale-in that could terminate instances serving active connections. This was a deliberate choice caught during code review.

**Single NAT Gateway (cost tradeoff)**
One NAT Gateway serves all three AZs. In production, you would deploy one per AZ for fault tolerance. For this dev environment, the cost saving (~$90/month) was the right tradeoff.

---

## Project Structure

```
├── VPC.tf                  # VPC, subnets, IGW, NAT, route tables
├── LoadBalancer.tf         # ALB security group, ALB, target group, listener
├── launch_templates.tf     # EC2 security group, launch template
├── Auto_scaling_Group.tf   # ASG, scale-up/down policies, CloudWatch alarms
├── variables.tf            # All variable declarations
├── provider.tf             # AWS provider configuration
├── Scripts/
│   └── install_apache.sh   # User data: installs Apache on EC2 launch
└── .gitignore              # Excludes tfstate, .terraform/, .DS_Store
```

---

## How to Deploy

**Prerequisites**
- Terraform installed
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create VPC, EC2, ALB, ASG, CloudWatch resources

**Steps**
```bash
# Clone the repo
git clone https://github.com/merakiware/terraform-aws-ha-web-infrastructure
cd terraform-aws-ha-web-infrastructure

# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Deploy (approx. 3-5 minutes)
terraform apply

# Get the ALB DNS name
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[0].DNSName' \
  --output text

# Open in browser
http://<alb-dns-name>

# Destroy when done (important — NAT Gateway incurs hourly charges)
terraform destroy
```

---

## Verification

After `terraform apply` completes:

1. Navigate to **EC2 → Target Groups → apache-web-tg → Targets**
2. Wait for both instances to show **Healthy** status (~3 minutes)
3. Open the ALB DNS name in a browser — you should see:
   ```
   This instance is: ip-10-0-x-x.ec2.internal
   ```
4. Refresh the page — the hostname changes as the ALB routes to different instances

---

## Cost Estimate

| Resource | Cost for 1 hour |
|---|---|
| NAT Gateway | ~$0.05 |
| ALB | Free tier eligible |
| 2x EC2 t2.micro | Free tier eligible |
| CloudWatch alarms | Free tier (10 alarms) |
| **Total** | **~$0.05** |

> ⚠️ Run `terraform destroy` immediately after testing. NAT Gateways cost ~$33/month if left running.

---

## Future Improvements

- [ ] **S3 remote state backend** — Current setup uses local state which works for solo development. Team environments require remote state with DynamoDB locking to prevent concurrent modifications from corrupting infrastructure.

- [ ] **GitHub Actions CI/CD** — Next step is automating `terraform plan` on every pull request and `terraform apply` on merge to main, so infrastructure changes go through the same review process as application code.

- [ ] **HTTPS / SSL certificate** — HTTP only for this demo to keep the scope focused. Production would require an ACM certificate and a second ALB listener on port 443 with HTTP → HTTPS redirect.

- [ ] **Convert to Terraform modules** — VPC and ASG configurations would benefit from being extracted into reusable modules. This would allow deploying identical infrastructure across dev, staging, and prod environments without duplicating code.

- [ ] **Multi-AZ NAT Gateways** — Deliberately deployed a single NAT Gateway to reduce cost (~$90/month savings for 3 gateways vs 1). The tradeoff is that if `us-east-1a` goes down, private subnets in other AZs lose outbound internet. Acceptable for a dev environment, not for production.

- [ ] **IAM role + SSM access** — Would attach an instance profile to EC2s allowing AWS Systems Manager access without SSH keys or open ports. This eliminates credential management entirely and is the standard approach in production environments.

---

## Author

Built as part of a DevOps/Cloud Engineering portfolio. Based in NYC
