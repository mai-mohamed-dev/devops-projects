# Terraform + Ansible: Multi-Tier Web Application on AWS

![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/Cloud-AWS-232F3E?logo=amazonaws&logoColor=white)
![Ansible](https://img.shields.io/badge/Config-Ansible-EE0000?logo=ansible&logoColor=white)
![Ubuntu](https://img.shields.io/badge/OS-Ubuntu%2024.04-E95420?logo=ubuntu&logoColor=white)

A hands-on DevOps project that combines **Infrastructure as Code** (Terraform) with **configuration management** (Ansible) to build a production-style, multi-tier web application environment on AWS.

Terraform provisions the network, security rules, load balancer and four Linux servers. Ansible then configures what runs on those servers (Nginx, the application, MariaDB, RabbitMQ and Memcached), so no server is ever set up by hand.

## Project status

| Part | Status |
|---|---|
| Terraform: network, security groups, ALB, 4 EC2 instances | Implemented |
| Ansible: Nginx, application, MariaDB, RabbitMQ, Memcached | In progress |
| End-to-end application access through the ALB | Needs the Ansible step |

> Until Ansible installs Nginx on the app server, the ALB target is **unhealthy** and the ALB returns **503**. This is expected.

## Architecture

![AWS architecture](docs/images/architecture.svg)

**Request path:** user, then Internet, then Internet Gateway, then the Application Load Balancer (port 80), then Nginx on the app server, then the application. The app server talks to MariaDB (3306), RabbitMQ (5672) and Memcached (11211) in the private subnet. Private servers reach the internet for updates only through the NAT Gateway.

## Delivery workflow

![Delivery workflow](docs/images/workflow.svg)

1. Write Terraform (`.tf`) and Ansible (`.yml`) code.
2. Push it to GitHub.
3. Terraform creates the AWS infrastructure.
4. Ansible connects to the instances and configures them.
5. Users reach the application through the ALB DNS name.

## What Terraform builds

| Area | Resources |
|---|---|
| **Network** | `aws_vpc.main`, public subnet, second public subnet (for the ALB, in another AZ), private subnet |
| **Routing** | Internet Gateway, public and private route tables with associations, Elastic IP and NAT Gateway, private default route through the NAT |
| **Security groups** | `public-tier-sg` (ALB), `app-tier-sg`, `db-tier-sg`, `rabbitmq-tier-sg`, `memcached-tier-sg` |
| **Load balancing** | Application Load Balancer, HTTP listener on port 80, target group with health checks, app instance registered as target |
| **Compute** | 4 Ubuntu 24.04 `t3.medium` instances: app (public subnet), MariaDB, RabbitMQ, Memcached (private subnet) |
| **Access** | EC2 key pair, SSH to the app server from the admin IP only, private servers reachable only through the app server |

## Security model
- **Least privilege:** each backend accepts traffic only from the app server's security group, never from CIDR ranges.
- **Private by default:** database, broker and cache have no public IP and sit in the private subnet.
- **Restricted administration:** SSH reaches the app server only from `admin_cidr`. The private servers are reached through it (jump host).
- **RabbitMQ management UI** (port 15672) is intentionally not exposed.
- **No secrets in Git:** state files, `*.tfvars` and key files are ignored (see `.gitignore`).

## Repository layout

```
.
├── terraform/
│   ├── network.tf                    # VPC, subnets, routing, NAT, security groups, target group
│   ├── main.tf                     # AMI lookup, ALB, EC2 instances
│   ├── variables.tf
│   ├── providers.tf
│   └── outputs.tf
├── ansible/                       # playbooks and roles (in progress)
├── images/
│   ├── architecture.svg
│   └── workflow.svg
├── .gitignore
└── README.md
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) with the AWS provider v5 or newer
- An AWS account and credentials (`aws configure` or environment variables) allowed to create VPC, EC2 and ELB resources
- An **existing EC2 key pair** in the same region (`eu-north-1` by default)
- Your public IP address (for SSH access)
- [Ansible](https://docs.ansible.com/) for the configuration step
- Git

## Configuration

| Variable | Default | Description |
|---|---|---|
| `vpc_cidr` | `10.0.0.0/16` | VPC address range |
| `public_cidr` | `10.0.1.0/24` | Public subnet (app server, NAT Gateway) |
| `public_cidr_2` | `10.0.3.0/24` | Second public subnet (the ALB needs two AZs) |
| `private_cidr` | `10.0.2.0/24` | Private subnet (database, broker, cache) |
| `av_zone` | `eu-north-1a` | Availability zone for the main subnets |
| `av_zone_2` | `eu-north-1b` | Second zone, must differ from `av_zone` |
| `app_port` | `80` | Port the ALB targets on the app server (Nginx) |
| `key_name` | none (required) | Name of an existing EC2 key pair |
| `admin_cidr` | none (required) | Your IP in CIDR form |

Create `terraform/terraform.tfvars` (it is Git-ignored):

```hcl
key_name   = "my-key-pair"
admin_cidr = "Your IP in CIDR form"
```

## Getting started

```bash
git clone <your-repo-url>
cd <your-repo>/terraform

terraform init
terraform fmt -check
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## Outputs

| Output | Meaning |
|---|---|
| `alb_dns_name` / `app_url` | Address users open in a browser |
| `app_public_ip` | Public IP of the app server (SSH entry point) |
| `app_private_ip`, `db_private_ip`, `mq_private_ip`, `mem_private_ip` | Private addresses for the Ansible inventory |
| `vpc_id`, subnet, route table and security group IDs | For reference and troubleshooting |

```bash
terraform output
```

## Verifying the infrastructure

1. **SSH to the app server** (default user on Ubuntu images is `ubuntu`):
   ```bash
   ssh -i my-key-pair.pem ubuntu@<app_public_ip>
   ```
2. **SSH to a private server through the app server:**
   ```bash
   ssh -i my-key-pair.pem -J ubuntu@<app_public_ip> ubuntu@<db_private_ip>
   ```
3. **Check the target group:** AWS console, EC2, Target Groups, `app-tg`. It shows *unhealthy* until Nginx is running.
4. **Open the app:** `http://<alb_dns_name>` once Ansible has configured the servers.

## Configuration management with Ansible (in progress)

Planned roles, one per tier:

| Role | Target | Purpose |
|---|---|---|
| `common` | all servers | OS updates, security hardening, base packages |
| `nginx` | app server | Install Nginx and configure it as a reverse proxy |
| `app` | app server | Deploy and run the application on its internal port |
| `mariadb` | db server | Install MariaDB, create the database and user |
| `rabbitmq` | mq server | Install RabbitMQ, create users and vhosts |
| `memcached` | cache server | Install and configure Memcached |

Example inventory (private hosts reached through the app server):

```ini
[app]
APP_PUBLIC_IP

[db]
DB_PRIVATE_IP

[mq]
MQ_PRIVATE_IP

[cache]
MEM_PRIVATE_IP

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/my-key-pair.pem

[db:vars]
ansible_ssh_common_args='-o ProxyJump=ubuntu@APP_PUBLIC_IP'
# repeat the ProxyJump line for the mq and cache groups
```

Check connectivity with `ansible all -i inventory.ini -m ping`.

## Scaling

The ALB already spans two availability zones, and the app tier sits behind a target group, so adding application servers needs no redesign:

- create more app instances (for example with `count` or `for_each` on `aws_instance.app`),
- register each one with the target group,
- keep them in `app-tier-sg`, and add them to the Ansible `[app]` group.

## Cost and cleanup

The **NAT Gateway**, the **Application Load Balancer** and four `t3.medium` instances are billed by the hour. Destroy the environment when you finish practicing:

```bash
terraform destroy
```

## Roadmap

- [ ] Complete the Ansible roles and a single `site.yml` playbook
- [ ] HTTPS listener on the ALB with an ACM certificate
- [ ] Remote Terraform state (S3 with locking)
- [ ] AWS Systems Manager (SSM) for keyless access instead of SSH keys
- [ ] Auto Scaling Group for the application tier
- [ ] CI checks (`terraform fmt`, `terraform validate`) with GitHub Actions

## What this project demonstrates

- Designing an isolated VPC with public and private subnets, routing and NAT using Terraform
- Provisioning EC2 instances with dedicated, least-privilege security groups
- Putting an Application Load Balancer with health checks in front of an application tier
- Separating infrastructure provisioning (Terraform) from configuration management (Ansible)
- Keeping infrastructure and configuration in Git for repeatable deployments

## Author

Your Name, [GitHub profile](https://github.com/your-username)
