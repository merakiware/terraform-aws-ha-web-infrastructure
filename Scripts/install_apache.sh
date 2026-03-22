#!/bin/bash
yum update -y
yum install httpd -y
systemctl enable --now httpd
echo "This instance is: $(hostname -f)" > /var/www/html/index.html