#!/bin/bash

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
php composer-setup.php --filename=composer --install-dir=/usr/local/bin && \
php -r "unlink('composer-setup.php');"