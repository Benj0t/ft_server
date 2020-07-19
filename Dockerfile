# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: bemoreau <bemoreau@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2020/02/20 19:28:55 by bemoreau          #+#    #+#              #
#    Updated: 2020/02/21 14:03:43 by bemoreau         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:buster

MAINTAINER bemoreau <bemoreau@student.42.fr>

# Installing the dependencies
## Adding some required repositories
RUN apt update
RUN apt install software-properties-common dirmngr gnupg2 ca-certificates -y
RUN apt-key adv --fetch-keys "https://nginx.org/keys/nginx_signing.key"
RUN add-apt-repository "deb http://nginx.org/packages/mainline/debian buster nginx" -y
RUN apt-key adv --fetch-keys "https://mariadb.org/mariadb_release_signing_key.asc"
RUN add-apt-repository "deb [arch=amd64] http://ftp.igh.cnrs.fr/pub/mariadb/repo/10.4/debian buster main" -y
RUN apt-key adv --fetch-keys "https://packages.sury.org/php/apt.gpg"
RUN add-apt-repository "deb http://packages.sury.org/php buster main" -y
## Updating things
RUN apt update
RUN apt upgrade -y
## Installing all we need
RUN apt install gettext-base -y
RUN apt install nginx -y
RUN apt install mariadb-server -y
RUN apt install php7.4-fpm php7.4-common php7.4-mysql php7.4-curl \
php7.4-json php7.4-gd php7.4-intl php7.4-sqlite3 php7.4-gmp \
php7.4-mbstring php7.4-xml php7.4-zip php7.4-soap php7.4-xmlrpc \
php7.4-imap php7.4-bz2 php7.4-bcmath -y

# Setting up mariadb-server
## Fixing the installation
RUN cp /usr/share/mysql/mysql.init /etc/init.d/mariadb
RUN chmod 755 /etc/init.d/mariadb
RUN update-rc.d mariadb defaults
RUN mkdir -p /var/run/mysqld
RUN chown mysql:root /var/run/mysqld

# Setting up Wordpress and phpMyAdmin
## Files
COPY srcs/web.tar.gz /tmp
RUN mkdir -p /var/www
RUN tar xzf /tmp/web.tar.gz -C /var/www
RUN rm -f /tmp/web.tar.gz
## Permissions
RUN chown -R www-data:www-data /var/www/ft_server
RUN chmod -R 700 /var/www/ft_server
## Database
COPY srcs/wordpress.sql /tmp
RUN service mariadb start && \
mysql -Bse "CREATE USER 'wordpress'@'localhost' IDENTIFIED BY 'j5ufPOh66pUP9unf'; \
CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY 'mEa9t25g3C5jW2AG'; \
CREATE DATABASE wordpress; \
CREATE DATABASE phpmyadmin; \
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost'; \
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'phpmyadmin'@'localhost'; \
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Uib36u247YSqKtR3'; \
FLUSH PRIVILEGES;" && \
mysql -u root -pUib36u247YSqKtR3 wordpress < /tmp/wordpress.sql && \
mysql -u root -pUib36u247YSqKtR3 < /var/www/ft_server/phpmyadmin/sql/create_tables.sql
RUN rm -f /tmp/wordpress.sql

# Setting up the SSL certificate
RUN openssl req -newkey rsa:4096 -x509 -sha3-256 -days 365 -nodes \
-subj "/C=FR/ST=Paris/L=Paris/O=42/OU=Student Projects/CN=ft_server" \
-out /etc/ssl/private/ft_server.crt -keyout /etc/ssl/private/ft_server.key

# Setting up Nginx server
## Configuration
COPY srcs/nginx/nginx.conf /etc/nginx
COPY srcs/nginx/ft_server.conf /etc/nginx/conf.d
RUN rm -f /etc/nginx/conf.d/default.conf
RUN chmod -R 600 /etc/nginx/conf.d/ft_server.conf

# Setting ENV VARIABLE
ENV NGINX_AUTOINDEX on

# Replacing ENV Variable
RUN envsubst '${NGINX_AUTOINDEX}' < /etc/nginx/conf.d/ft_server.conf | tee /etc/nginx/conf.d/ft_server.conf
# Setting up php-fpm
## Fixing the installation
RUN mkdir -p /var/run/php
RUN chown www-data:www-data /var/run/php
## Configuration
COPY srcs/php-fpm/ft_server.conf /etc/php/7.4/fpm/pool.d

# Starting the daemons
ENTRYPOINT service mariadb start && \
service nginx start && \
service php7.4-fpm start && \
/bin/bash

# Expose HTTP and HTTPS ports
EXPOSE 80/tcp
EXPOSE 443/tcp
