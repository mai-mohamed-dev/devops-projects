DB_ROOT_PASS="root"
APP_USER="admin"

APP_DB_PASS="admin123"
SRC_DIR="/opt/vprofile-project"

sudo yum update -y
sudo yum install epel-release -y
sudo yum install -y mariadb-server
sudo yum install -y git
sudo systemctl start mariadb
sudo systemctl enable --now mariadb

# fixed Reults
#mariadb-secure-installation <<EOF
                                 
#Y                                 
#${DB_ROOT_PASS}                   
#${DB_ROOT_PASS}                   
#Y                                
#Y                                 
#Y                                 
#Y                                 
#EOF

# mysql_secure_installation steps, plus the app database and user
sudo mysql -u root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'$(hostname)';
DROP USER IF EXISTS 'root'@'%';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS accounts;
CREATE USER IF NOT EXISTS '${APP_USER}'@'%' IDENTIFIED BY '${APP_DB_PASS}';
GRANT ALL PRIVILEGES ON accounts.* TO '${APP_USER}'@'%';
FLUSH PRIVILEGES;
SQL

sudo mkdir -p $SRC_DIR
sudo chmod -R 755 $SRC_DIR
cd $SRC_DIR
sudo git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
sudo mysql -u root -p${DB_ROOT_PASS} accounts < src/main/resources/db_backup.sql
  

# Test the database connection and the tables
#mysql -u root -p${DB_ROOT_PASS} accounts
#mysql> show tables;
#mysql> exit;

sudo systemctl restart mariadb

#sudo systemctl start firewalld
sudo systemctl disable firewalld
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl restart mariadb



