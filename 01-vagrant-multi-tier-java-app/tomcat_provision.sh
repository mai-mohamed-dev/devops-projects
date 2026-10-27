SRC_DIR="/opt/vprofile-project"

sudo dnf update -y
sudo dnf install epel-release -y


sudo dnf -y install java-11-openjdk java-11-openjdk-devel
sudo dnf install git wget unzip zip -y
sudo dnf install git maven wget -y

cd /tmp/
sudo wget "https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz"
sudo tar xzvf apache-tomcat-9.0.75.tar.gz
sudo useradd --home-dir /usr/local/tomcat --shell /sbin/nologin tomcat
sudo cp -r /tmp/apache-tomcat-9.0.75/* /usr/local/tomcat/


sudo chown -R tomcat.tomcat /usr/local/tomcat
sudo chmod +x /usr/local/tomcat/bin/*.sh

sudo rm -rf /etc/systemd/system/tomcat.service

sudo cat <<'EOF'>> /etc/systemd/system/tomcat.service
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
EOF

sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat

#sudo systemctl start firewalld
#sudo systemctl enable firewalld
#sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
#sudo firewall-cmd --reload

cd /tmp/
sudo wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip
sudo unzip apache-maven-3.9.9-bin.zip
sudo cp -r apache-maven-3.9.9 /usr/local/maven3.9
sudo chown tomcat.tomcat /usr/local/maven3.9 -R
sudo ln -sf /usr/local/maven3.9/bin/mvn /usr/bin/mvn

sudo mkdir -p $SRC_DIR
sudo chmod -R 755 $SRC_DIR
cd ${SRC_DIR}
sudo git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
sudo rm -rf ${SRC_DIR}/vprofile-project/src/main/resources/application.properties
sudo cp /vagrant/application.properties ${SRC_DIR}/vprofile-project/src/main/resources/application.properties


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