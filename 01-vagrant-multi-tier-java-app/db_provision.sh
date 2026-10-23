yum update -y
yum install epel-release -y
yum install -y mariadb-server
systemctl start mariadb
systemctl enable --now mariadb



