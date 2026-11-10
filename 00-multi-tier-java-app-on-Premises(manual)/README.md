# Automated Provisioning of a Multi-Tier Java Web App via Vagrant and Shell Scripting

![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?logo=vagrant&logoColor=white)
![VirtualBox](https://img.shields.io/badge/VirtualBox-21416F?logo=virtualbox&logoColor=white)
![CentOS](https://img.shields.io/badge/CentOS_Stream_9-262577?logo=centos&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?logo=nginx&logoColor=white)
![Tomcat](https://img.shields.io/badge/Tomcat-F8DC75?logo=apachetomcat&logoColor=black)
![Maven](https://img.shields.io/badge/Maven-C71A36?logo=apachemaven&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?logo=mariadb&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/RabbitMQ-FF6600?logo=rabbitmq&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=white)
![Java](https://img.shields.io/badge/Java_11-ED8B00?logo=openjdk&logoColor=white)
![Memcached](https://img.shields.io/badge/Memcached-3A8F3A)

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

> 🛠️ Status: 🚧 In progress
>
> Architecture inspired by: `<course or source, if any>`. The Vagrantfile and this write-up are my own.

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

```
User  -->  nginx :80  -->  tomcat :8080  -->  db :3306        (MariaDB)
                                         -->  memcache :11211 (cache)
                                         -->  rabbitmq :5672  (queue)
```

> The full target design also has a load balancer in front of two Nginx and two Tomcat servers, two Memcached nodes, and NFS shared storage. This build runs **one VM per tier**.

## 🖥️ Virtual Machines

All five VMs use the box `eurolinux-vagrant/centos-stream-9` (version `9.0.43`), a private network, and the default 1 CPU.

| VM | Hostname | IP | RAM | Main software |
|---|---|---|---|---|
| Database | `db` | `192.168.56.15` | 2 GB | MariaDB |
| Cache | `memcache` | `192.168.56.14` | 1 GB | Memcached |
| Queue | `rabbitmq` | `192.168.56.13` | 1 GB | RabbitMQ 3.8 |
| App | `tomcat` | `192.168.56.12` | 2 GB | Java 11, Tomcat 9.0.75, Maven 3.9.9 |
| Web | `nginx` | `192.168.56.11` | 1 GB | Nginx |

**Total: about 7 GB of RAM for the VMs.**

**Setup order matters.** The backend services must exist before the app that connects to them, so I configured the VMs in this order:

`db` → `memcache` → `rabbitmq` → `tomcat` → `nginx`

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

## 🚀 Quick Start

```bash
git clone https://github.com/mai-mohamed-dev/devops-projects.git
cd devops-projects/01-vagrant-multi-tier-java-app

# create the five VMs
vagrant up

# check them
vagrant status

# then configure each VM by hand, in order: db, memcache, rabbitmq, tomcat, nginx
vagrant ssh db
# ...run the commands from the "Manual Setup" section below, then exit
```

Open **http://192.168.56.11** to reach the application through Nginx. Because the hostmanager plugin updates your hosts file, **http://nginx** should work too.

Useful commands:

```bash
vagrant ssh tomcat            # log in to a VM
vagrant halt                  # stop all VMs
vagrant destroy -f            # delete everything (the manual setup must be repeated afterwards)
```

## 📁 Project Structure

```
01-vagrant-multi-tier-java-app/
├── README.md                    # this guide, including every manual command
├── Vagrantfile                  # five VMs, networks, resources
└── docs/images/                 # screenshots and diagrams
```

## ⚙️ How It Works
1. `vagrant up` creates each VM from the same pinned box, with its own IP and memory.
2. The hostmanager plugin writes every VM's name and IP into each VM's `/etc/hosts` (and your host's), so services connect by name.
3. I log in to each VM with `vagrant ssh <name>` and run the commands for that tier only (see the next section).
4. On the Tomcat VM I clone the application source, build it with Maven, and deploy the WAR as `ROOT.war`.
5. Tomcat connects to the database, cache and queue by name (`db`, `memcache`, `rabbitmq`) through `application.properties`.
6. Nginx proxies requests to `tomcat:8080`.

## 🔧 Manual Setup

Run each block **on that VM only**. Lines starting with `#` are comments.

<details>
<summary><b>1. db VM (MariaDB)</b></summary>

Install, start, and enable the service:

```bash
sudo yum update -y
sudo yum install epel-release -y
sudo yum install -y mariadb-server
sudo yum install -y git
sudo systemctl start mariadb
sudo systemctl enable --now mariadb
```

Secure the server and create the app database and user. Open the shell, then run the SQL inside it:

```bash
sudo mysql -u root -proot accounts
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'$(hostname)';
DROP USER IF EXISTS 'root'@'%';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS accounts;
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%';
FLUSH PRIVILEGES;
```

Load the application data:

```bash
sudo mkdir -p /opt/vprofile-project
sudo chmod -R 755 /opt/vprofile-project
cd /opt/vprofile-project
sudo git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
sudo mysql -u root -proot accounts < src/main/resources/db_backup.sql
```

Optional check of the tables:

```bash
mysql -u root -p accounts
# mysql> show tables;
# mysql> exit;
```

Restart and open the firewall:

```bash
sudo systemctl restart mariadb
sudo systemctl disable firewalld
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl restart mariadb
```

</details>

<details>
<summary><b>2. memcache VM (Memcached)</b></summary>

```bash
sudo yum update -y
sudo yum install epel-release -y
sudo yum install memcached -y
sudo systemctl start memcached
sudo systemctl enable memcached
sudo systemctl status memcached

# listen on all addresses instead of only 127.0.0.1
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
sudo systemctl restart memcached

# firewall
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --add-port=11211/tcp
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --add-port=11111/udp
sudo firewall-cmd --runtime-to-permanent

# start with TCP and UDP ports
sudo memcached -p 11211 -U 11111 -u memcached -d
```

</details>

<details>
<summary><b>3. rabbitmq VM (RabbitMQ)</b></summary>

```bash
sudo yum update -y
sudo yum install epel-release -y
sudo yum install wget -y
cd /tmp/
sudo dnf -y install centos-release-rabbitmq-38
sudo dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server
sudo systemctl enable --now rabbitmq-server

# allow remote logins, then create the app user
sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
sudo rabbitmqctl add_user test test
sudo rabbitmqctl set_user_tags test administrator
sudo rabbitmqctl set_permissions -p "/" test ".*" ".*" ".*"
sudo systemctl restart rabbitmq-server

# firewall and start on boot
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --add-port=5672/tcp
sudo firewall-cmd --runtime-to-permanent
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server
```

</details>

<details>
<summary><b>4. tomcat VM (Java, Tomcat, Maven, application)</b></summary>

Install Java and tools:

```bash
sudo dnf update -y
sudo dnf install epel-release -y
sudo dnf -y install java-11-openjdk java-11-openjdk-devel
sudo dnf install git wget unzip zip -y
sudo dnf install git maven wget -y
```

Install Tomcat 9.0.75:

```bash
cd /tmp/
sudo wget "https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz"
sudo tar xzvf apache-tomcat-9.0.75.tar.gz
sudo useradd --home-dir /usr/local/tomcat --shell /sbin/nologin tomcat
sudo cp -r /tmp/apache-tomcat-9.0.75/* /usr/local/tomcat/
sudo chown -R tomcat.tomcat /usr/local/tomcat
sudo chmod +x /usr/local/tomcat/bin/*.sh
sudo rm -rf /etc/systemd/system/tomcat.service
```

Create `/etc/systemd/system/tomcat.service`:

```ini
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=simple
User=tomcat
Group=tomcat
WorkingDirectory=/usr/local/tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk"
Environment="CATALINA_PID=/usr/local/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/usr/local/tomcat"
Environment="CATALINA_BASE=/usr/local/tomcat"
ExecStart=/usr/local/tomcat/bin/catalina.sh run
ExecStop=/usr/local/tomcat/bin/shutdown.sh
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat
```

Install Maven 3.9.9:

```bash
cd /tmp/
sudo wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip
sudo unzip apache-maven-3.9.9-bin.zip
sudo cp -r apache-maven-3.9.9 /usr/local/maven3.9
sudo chown tomcat.tomcat /usr/local/maven3.9 -R
sudo ln -sf /usr/local/maven3.9/bin/mvn /usr/bin/mvn
```

Get the application source and replace its configuration:

```bash
sudo mkdir -p /opt/vprofile-project
sudo chmod -R 755 /opt/vprofile-project
cd /opt/vprofile-project
sudo git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
sudo rm -rf /opt/vprofile-project/vprofile-project/src/main/resources/application.properties
```

Create `/opt/vprofile-project/vprofile-project/src/main/resources/application.properties`:

```properties
#JDBC Configutation for Database Connection
jdbc.driverClassName=com.mysql.cj.jdbc.Driver
jdbc.url=jdbc:mysql://db:3306/accounts?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull
jdbc.username=admin
jdbc.password=admin123

#Memcached Configuration
memcached.active.host=memcache
memcached.active.port=11211

#For StandBy Host
memcached.standBy.host=127.0.0.2
memcached.standBy.port=11211

#RabbitMq Configuration
rabbitmq.address=rabbitmq
rabbitmq.port=5672
rabbitmq.username=test
rabbitmq.password=test

#Elasticsearch Configuration
elasticsearch.host=localhost
elasticsearch.port=9300
elasticsearch.cluster=vprofile
elasticsearch.node=vprofilenode

spring.servlet.multipart.max-file-size=128KB
spring.servlet.multipart.max-request-size=128KB
logging.level.org.springframework.security=DEBUG

# application.properties
spring.security.user.name=admin_vp
spring.security.user.password=admin_vp
spring.security.user.roles=ADMIN
spring.mvc.view.prefix=/WEB-INF/views/
spring.mvc.view.suffix=.jsp

# Hibernate SQL Queries
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.format_sql=false
logging.level.org.hibernate.SQL=OFF
logging.level.org.hibernate.type=OFF

# Debug Logging for SecurityServiceImpl
logging.level.com.visualpathit.account.service.SecurityServiceImpl=OFF
```

Build and deploy:

```bash
sudo /usr/local/maven3.9/bin/mvn install
sudo systemctl stop tomcat
sudo rm -rf /usr/local/tomcat/webapps/ROOT
sudo rm -rf /usr/local/tomcat/webapps/ROOT.war
sudo cp target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
sudo chown tomcat.tomcat /usr/local/tomcat/webapps -R
sudo systemctl start tomcat
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl restart tomcat
```

</details>

<details>
<summary><b>5. nginx VM (reverse proxy)</b></summary>

```bash
sudo dnf update -y
sudo dnf upgrade -y
sudo dnf install -y nginx
sudo systemctl start nginx
sudo systemctl enable --now nginx
```

Create `/etc/nginx/conf.d/vproapp.conf`:

```nginx
upstream vproapp {
    server tomcat:8080;
}

server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://vproapp;
    }
}
```

Open the firewall, allow Nginx to reach Tomcat, and restart:

```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo setsebool -P httpd_can_network_connect 1
sudo systemctl restart nginx
```

</details>

### Notes on the manual run
- **First MariaDB login:** the command uses `-proot` before the root password is set. On a fresh install, use `sudo mysql` first, then run the `ALTER USER` statement.
- **`$(hostname)` in SQL:** the shell does not expand it inside the MariaDB prompt, so use the real host name or skip that line.
- **Firewall:** `systemctl disable firewalld` only stops it starting at boot. Rules added while it runs are lost on reboot unless it is enabled.
- **Memcached:** the last command starts a second process next to the systemd service. If port 11211 is already in use, stop the service first.
- **Maven on the Tomcat VM:** it is installed twice (`dnf` and manually). The build uses the manual copy in `/usr/local/maven3.9`.

## 🔒 Security Notes
- Credentials in the commands (`root`, `admin123`, `test`, `admin_vp`) are **lab-only**. Replace them for any real use, and keep real values out of the repo.
- Every service is on the private network only.
- Firewall state on the manual run: `firewalld` is disabled on `db` and `tomcat`; the ports below were opened on `memcache`, `rabbitmq` and `nginx`. Open ports only between the VMs that need them if you harden this.
- SELinux settings were not changed, except enabling `httpd_can_network_connect` on the `nginx` VM so it can reach Tomcat.

| Service | Port |
|---|---|
| Nginx | 80 (and 443 allowed) |
| Tomcat | 8080 |
| MariaDB | 3306 |
| Memcached | 11211 (TCP), 11111 (UDP) |
| RabbitMQ | 5672 |



## 📄 License
[MIT](../LICENSE)