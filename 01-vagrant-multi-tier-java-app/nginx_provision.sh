sudo dnf update -y
sudo dnf upgrade -y

sudo dnf install -y nginx
sudo systemctl start nginx
sudo systemctl enable --now nginx

cat > /etc/nginx/conf.d/vproapp.conf <<'EOF'
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
EOF

sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-service=http    
sudo firewall-cmd --permanent --add-service=https    
sudo firewall-cmd --reload

sudo setsebool -P httpd_can_network_connect 1
sudo systemctl restart nginx