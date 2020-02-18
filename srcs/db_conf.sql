echo "CREATE DATABASE wordpress;" | mysql -u root 
echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'ft_server';" | mysql -u root
echo "FLUSH PRIVILEGES;" | mysql -u root
echo "update mysql.user set plugin = 'mysql_native_password' where user='root';" | mysql -u root