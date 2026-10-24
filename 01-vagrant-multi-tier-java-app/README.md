# Automated Provisioning of a Multi-Tier Java Web App via Vagrant and Shell Scripting

![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?logo=vagrant&logoColor=white)
![VirtualBox](https://img.shields.io/badge/VirtualBox-21416F?logo=virtualbox&logoColor=white)
![CentOS](https://img.shields.io/badge/CentOS_Stream_9-262577?logo=centos&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?logo=nginx&logoColor=white)
![Tomcat](https://img.shields.io/badge/Tomcat-F8DC75?logo=apachetomcat&logoColor=black)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?logo=mysql&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/RabbitMQ-FF6600?logo=rabbitmq&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=white)

> 🛠️ Status: 🚧 In progress
>
> Architecture inspired by: `<course or source, if any>`. The Vagrantfile, scripts, and this write-up are my own.

## 📌 Overview
A complete multi-tier Java web application stack, built from scratch with **one command** (`vagrant up`). Each tier runs on its own CentOS Stream 9 VM and is configured automatically by its own shell script, so the whole environment can be destroyed and rebuilt in minutes with the same result.

**Goal:** replace manual, error-prone server setup with a repeatable, version-controlled build.

## 🏗️ Architecture

| Tier | VM | Role |
|---|---|---|
| Web | `nginx` | Receives client traffic and proxies it to Tomcat |
| Application | `tomcat` | Runs the Java web application |
| Messaging | `rabbitmq` | Message broker for asynchronous work |
| Cache | `memcache` | Reduces load on the database |
| Database | `db` | Persistent application data |

> The full target design also has a load balancer in front of two Nginx and two Tomcat servers, two Memcached nodes, and NFS shared storage. This build runs **one VM per tier**.

## 🖥️ Virtual Machines

All five VMs use the box `eurolinux-vagrant/centos-stream-9` (version `9.0.43`), a private network, and the default 1 CPU.

| VM | Hostname | IP | RAM | Provisioning script |
|---|---|---|---|---|
| Database | `db` | `192.168.56.15` | 2 GB | `db_provision.sh` |
| Cache | `memcache` | `192.168.56.14` | 1 GB | `memcache_provision.sh` |
| Queue | `rabbitmq` | `192.168.56.13` | 1 GB | `rabbitmq_provision.sh` |
| App | `tomcat` | `192.168.56.12` | 2 GB | `tomcat_provision.sh` |
| Web | `nginx` | `192.168.56.11` | 1 GB | `nginx_provision.sh` |

**Total: about 7 GB of RAM for the VMs.**

**Boot order matters.** Vagrant starts machines in the order they appear in the Vagrantfile, so backend services exist before the app that connects to them:

`db` → `memcache` → `rabbitmq` → `tomcat` → `nginx`

## 🧰 Tech Stack

| Tool | Why |
|---|---|
| Vagrant + VirtualBox | Reproducible local VMs from a single file |
| vagrant-hostmanager | VMs reach each other by name (`db`, `memcache`, …) instead of IPs |
| Shell scripts | Simple, readable provisioning, one script per tier |
| CentOS Stream 9 | Base OS for every VM |
| Nginx | Web server and reverse proxy |
| Tomcat + Java (`<JDK version>`) | Runs the Java web application |
| MySQL | Relational database |
| Memcached | In-memory cache |
| RabbitMQ | Message broker |

## ✅ Prerequisites
- Vagrant and VirtualBox installed
- Virtualization enabled in BIOS
- The hostmanager plugin: `vagrant plugin install vagrant-hostmanager`
- About 8 GB of free RAM and `<Y>` GB of free disk
- Admin rights: the plugin edits your computer's hosts file (`manage_host` is on), so run your terminal as administrator on Windows, or enter your password when `sudo` asks on Linux or macOS

## 🚀 Quick Start

```bash
git clone https://github.com/mai-mohamed-dev/devops-projects.git
cd devops-projects/01-vagrant-multi-tier-java-app

# put the application in app_src/ (build it first if needed)

# create and provision every VM
vagrant up

# check them
vagrant status
```

Open **http://192.168.56.11** to reach the application through Nginx. Because the hostmanager plugin updates your hosts file, **http://nginx** should work too.

Useful commands:

```bash
vagrant ssh tomcat            # log in to a VM
vagrant provision tomcat      # re-run one provisioning script
vagrant halt                  # stop all VMs
vagrant destroy -f            # delete everything
```

## 📁 Project Structure

```
01-vagrant-multi-tier-java-app/
├── README.md
├── Vagrantfile                  # all five VMs, networks, resources
├── db_provision.sh              # MySQL: install, create database and user
├── memcache_provision.sh        # Memcached: install, listen on private IP
├── rabbitmq_provision.sh        # RabbitMQ: install, create user
├── tomcat_provision.sh          # Tomcat: install, deploy app, systemd service
├── nginx_provision.sh           # Nginx: install, proxy config
├── app_src/                     # application files, synced into the Tomcat VM
└── docs/images/                 # screenshots and diagrams
```

## ⚙️ How It Works
1. `vagrant up` creates each VM from the same pinned box, with its own IP and memory.
2. The hostmanager plugin writes every VM's name and IP into each VM's `/etc/hosts` (and your host's), so services connect by name.
3. One shell provisioner per VM installs and configures only that tier.
4. `app_src/` on your computer is shared into the Tomcat VM at `/vagrant`.
5. Tomcat connects to the database, cache, and queue by their private addresses.
6. Nginx proxies requests to Tomcat.

## 🔒 Security Notes
- Credentials in the scripts are **lab-only**. Replace them for any real use, and keep real values out of the repo (commit `.env.example`, ignore `.env`).
- Every service is on the private network only.
- Open ports only between the VMs that need them, and keep SELinux **enforcing**. If a connection fails, fix the policy or label instead of disabling it.

| Service | Port |
|---|---|
| Nginx | 80 |
| Tomcat | 8080 |
| MySQL | 3306 |
| Memcached | 11211 |
| RabbitMQ | 5672 (management UI 15672) |

## 🧪 Verify It Works

```bash
# services are running (run inside each VM)
systemctl status <service>

# the app answers through Nginx (from your host)
curl -I http://192.168.56.11

# backends are reachable from the tomcat VM
nc -zv db 3306
nc -zv memcache 11211
nc -zv rabbitmq 5672
```

Finish with a full rebuild test: `vagrant destroy -f` then `vagrant up` should give the same working result.

## ✅ Result
- All five tiers built and configured by one command
- Application reachable through Nginx
- Full environment rebuilt from scratch in `<N>` minutes

![Application running](docs/images/app.png)
![vagrant status](docs/images/vagrant-status.png)


## 📄 License
[MIT](../LICENSE)
