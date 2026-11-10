
> # Manual Provisioning of a Multi-Tier Java Web App on Vagrant VMs

![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?logo=vagrant&logoColor=white)
![VirtualBox](https://img.shields.io/badge/VirtualBox-21416F?logo=virtualbox&logoColor=white)
![CentOS](https://img.shields.io/badge/CentOS_Stream_9-262577?logo=centos&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?logo=nginx&logoColor=white)
![Tomcat](https://img.shields.io/badge/Tomcat-F8DC75?logo=apachetomcat&logoColor=black)
![Maven](https://img.shields.io/badge/Maven-C71A36?logo=apachemaven&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?logo=mariadb&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/RabbitMQ-FF6600?logo=rabbitmq&logoColor=white)
![Java](https://img.shields.io/badge/Java_11-ED8B00?logo=openjdk&logoColor=white)
![Memcached](https://img.shields.io/badge/Memcached-3A8F3A)


## 📌 Overview
A complete multi-tier Java web application stack running on five CentOS Stream 9 VMs. Vagrant creates the VMs, and I then configured **each tier manually**: I logged in to every VM with `vagrant ssh` and ran the install and configuration commands one by one, in dependency order.

**Goal:** understand how each tier is installed, configured, secured and connected to the others by doing it by hand. The commands in this README are the exact steps I ran, so the setup can be repeated.

## 🏗️ Architecture

| Tier | VM | Role |
|---|---|---|
| Web | `nginx` | Receives client traffic and proxies it to Tomcat |
| Application | `tomcat` | Runs the Java web application |
| Messaging | `rabbitmq` | Message broker for asynchronous work |
| Cache | `memcache` | Reduces load on the database |
| Database | `db` | Persistent application data |



## 🧰 Tech Stack

| Tool | Why |
|---|---|
| Vagrant + VirtualBox | Reproducible local VMs from a single file |
| vagrant-hostmanager | VMs reach each other by name (`db`, `memcache`, …) instead of IPs |
| Manual commands (`yum`/`dnf`, `systemctl`, `firewall-cmd`) | Configure each tier by hand, one VM at a time |
| CentOS Stream 9 | Base OS for every VM |
| Nginx | Web server and reverse proxy |
| Tomcat 9.0.75 + Java 11 | Runs the Java web application |
| Maven 3.9.9 | Builds the application on the Tomcat VM |
| MariaDB | Relational database |
| Memcached | In-memory cache |
| RabbitMQ 3.8 | Message broker |

## ✅ Prerequisites
- Vagrant and VirtualBox installed
- Virtualization enabled in BIOS
- The hostmanager plugin: `vagrant plugin install vagrant-hostmanager`
- About 8 GB of free RAM and `<Y>` GB of free disk
- Admin rights: the plugin edits your computer's hosts file (`manage_host` is on), so run your terminal as administrator on Windows, or enter your password when `sudo` asks on Linux or macOS

## 🔧 Manual Setup

Run each block **on that VM only**. Lines starting with `#` are comments.


## 📄 License
[MIT](../LICENSE)
