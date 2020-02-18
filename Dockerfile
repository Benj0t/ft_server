# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: bemoreau <bemoreau@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2020/02/17 17:31:05 by bemoreau          #+#    #+#              #
#    Updated: 2020/02/18 21:01:48 by bemoreau         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:buster

MAINTAINER bemoreau <bemoreau@student.42.fr>

# RUN => at building time
# CMD => at each run

#Updating Things
RUN apt update
RUN apt upgrade -y
# Install all we need
RUN apt install nginx -y
RUN apt install mariadb-server -y
RUN apt install php-fpm php-mysql php-mbstring -y

# Setting up mariadb-server
## Fixing the installation
RUN mkdir -p /var/run/mysqld
RUN chown mysql:root /var/run/mysqld
## Starting the server
RUN service mysql start
## Making the DB with the perms
RUN mysql -Bse "CREATE USER 'wordpress'@'localhost' IDENTIFIED BY 'j5ufPOh66pUP9unf';"
RUN mysql -Bse "CREATE DATABASE `wordpress`;"
RUN mysql -Bse "GRANT ALL PRIVILEGES ON `wordpress`.* TO 'wordpress'@'localhost';"
RUN mysql -Bse "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Uib36u247YSqKtR3';"
RUN mysql -Bse "FLUSH PRIVILEGES;"

# Setting up Nginx server
## Configuration
RUN mkdir -p /var/www/ft_server
COPY srcs/info.php /var/www/ft_server
RUN chown -R www-data:www-data /var/www/ft_server
RUN chmod -R 700 /var/www/ft_server
COPY srcs/ft_server.conf /etc/nginx/conf.d
RUN chmod -R 600 /etc/nginx/conf.d/ft_server.conf
## Wordpress
COPY srcs/web.tar.gz /tmp
COPY srcs/wordpress.sql /tmp
RUN tar xvf /tmp/web.tar.gz -C /var/www/ft_server
RUN mysql -u wordpress -pj5ufPOh66pUP9unf wordpress < /tmp/wordpress.sql
RUN rm -f /tmp/web.tar.gz
RUN rm -f /tmp/wordpress.sql

CMD service nginx start

EXPOSE 80/tcp
EXPOSE 443/tcp