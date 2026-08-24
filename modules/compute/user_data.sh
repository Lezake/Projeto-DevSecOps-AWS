#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Deployed via Terraform Pipeline!</h1>" > /var/www/html/index.html
