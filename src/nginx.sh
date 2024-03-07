#!/bin/bash

echo "--------------------------------------------------------------"
echo "---------------- Installing Nginx"
echo "--------------------------------------------------------------"

# Add latest nginx version repository
add-apt-repository ppa:ondrej/nginx-mainline

# nginx install and start
apt-get -y install nginx && service nginx start
