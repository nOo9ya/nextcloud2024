apt install -y python3-certbot-nginx
certbot --nginx -d cloud.noo9ya.com --no-eff-email --agree-tos -m noo9ya@gmail.com

/etc/letsencrypt/live/cloud.noo9ya.com/fullchain.pem;
certbot certonly --webroot --agree-tos --no-eff-email --email noo9ya@gmail.com -w /etc/letsencrypt/live -d cloud.noo9ya.com

# certbot certonly --webroot --agree-tos --no-eff-email --email noo9ya@gmail.com -w /etc/letsencrypt/live -d noo9ya.com -d www.noo9ya.com

sudo bash -c 'cat <(crontab -l) <(echo "*/10 * * * * sudo sh /var/app/current/mycrontab.sh") | crontab -'
