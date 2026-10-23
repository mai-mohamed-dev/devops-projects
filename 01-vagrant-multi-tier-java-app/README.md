
# 📚 DevOps Case Studies

Mini case studies from my DevOps learning journey. Each one covers a small, realistic scenario: the problem, the decisions I made, how I built it, the issues I hit, and what I learned.

> Some case studies are based on hands-on labs (for example, **KodeKloud** challenges). I credit the source in each one and write up the approach in my own words. Original projects are marked 🛠️.

## 🗂️ Case Studies

| # | Case Study | Tools | Type | Status |
|---|------------|-------|------|--------|
| 01 | [Deploying a web app to Kubernetes with Terraform](./01-terraform-k8s-deployment) | Terraform, Kubernetes | 🧪 Lab-based | ✅ Done |
| 02 | [Creating Multiple VMs using Vagrant](./02-vagrant-multi-vm-lab) | Vagrant, Nginx, PostgreSQL, Python | 🛠️ Own project | 🚧 In progress |

## 📁 Repository Structure
```
devops-case-studies/
├── README.md                      
├── LICENSE
├── .gitignore
└── 01-terraform-k8s-deployment/
    ├── README.md                 
    ├── provider.tf
    ├── main.tf
    └── images/
└── 02-vagrant-multi-vm-lab/
    ├── README.md
    ├── Vagrantfile              
    ├── web_provision.sh
    ├── app_provision.sh
    ├── db_provision.sh
    └── src/
         ├── app_src/
             ├── app.py
         ├── web_src/
             ├── 404.html
             ├── index.html             
                    
```

New case studies are added as numbered folders, each with its own README and code.
## 🧭 How Each Case Study Is Structured
Every folder has its own README with:
- **Scenario:** what problem it addresses
- **Architecture:** a simple diagram or flow
- **Key decisions:** what I chose and why
- **Implementation and how to run it**
- **Issues I hit:** problem → cause → fix
- **What I learned** and **next improvements**


## 🛠️ Tools I'm Working With
![VirtualBox](https://img.shields.io/badge/VirtualBox-21416F?logo=virtualbox&logoColor=white)
![CentOS](https://img.shields.io/badge/CentOS_Stream_9-262577?logo=centos&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?logo=flask&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?logo=git&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)
![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?logo=vagrant&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?logo=nginx&logoColor=white)


## 🎯 Goals
- Build one small, working case study at a time
- Document decisions and mistakes, not just final results
- Revisit each case study and improve it through pull requests

## 📄 License
Code in this repository is released under the [MIT License](./LICENSE). Lab-based case studies credit their original source.
