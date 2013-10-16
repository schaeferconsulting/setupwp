#!/bin/bash
#js at jasonschaefer.com

if [ -z "$1" ]
then
echo -e "\n You must specify a hostname! For example \"$0 example.com\" \n"
exit
fi
echo -e "\n hostname is: $1"
echo -e "\nThis will setup the dependencies for wordpress. This script is very Debian specific."
echo -e "You should read through the script to be familiar with what it is going to be doing. \n"
echo "Are you sure? (type y)"
read y
if [ "$y" != "y" ]
then
echo exiting
exit
fi

if [ $UID != 0 ]
then
echo "you are not root! you need to be root."
exit
fi
 
pass=`date |md5sum |head -c 9`
db=`echo $1 | tr -s . _`

echo -e "running: apt-get \n"
apt-get install apache2 php5 mysql-server php5-mysql || echo -e "\e[1;31mFAIL\e[0m"

echo -e "running: a2enmod \n"
a2enmod php5 ssl rewrite userdir || echo -e "\e[1;31mFAIL\e[0m"

echo -e "running: mkdir \n"
mkdir -p /var/www/$1

echo -e "running: wget\n"
wget -P /var/www/$1 https://wordpress.org/latest.tar.gz || echo -e "\e[1;31mFAIL\e[0m"

echo -e "running: tar\n"
tar xf /var/www/$1/latest.tar.gz --strip-components=1 -C /var/www/$1 || echo -e "\e[1;31mFAIL\e[0m"

echo -e "running: delete latest.tar.gz"
rm /var/www/$1/latest.tar.gz || echo -e "\e[1;31mFAIL\e[0m"

echo -e "running: chown\n"
chown -R www-data /var/www/$1 || echo -e "\e[1;31mFAIL\e[0m"

echo -e "running: make-ssl-cert\n"
make-ssl-cert /usr/share/ssl-cert/ssleay.cnf /etc/ssl/private/$1.crt || echo -e "\e[1;31mFAIL\e[0m"

echo -e "running: mysql create and grant\n"
echo "Enter mysql root password:"
echo `mysql -u root -p -e "create database $db; CREATE USER '$db'@'localhost' IDENTIFIED BY '$pass'; GRANT ALL PRIVILEGES ON $db . * TO '$db'@'localhost';"` || echo -e "\e[1;31mFAIL\e[0m"

echo -e "running: virtualhost config\n"
echo "<VirtualHost *:80> 
    ServerName $1
    ServerAlias $1 www.$1
    ServerAdmin webadmin@$1
    
    DocumentRoot /var/www/$1

    <Directory /var/www/$1/>
    	Options Indexes FollowSymLinks MultiViews
    	#AllowOverride AuthConfig Limit FileInfo Options
    	AllowOverride All
    	Order allow,deny
    	allow from all
    </Directory>

#    ScriptAlias /cgi-bin/ /var/www/$1/cgi-bin/
#    <Directory "/var/www/$1/cgi-bin">
#    	AllowOverride AuthConfig Limit Options
#    	Options ExecCGI -MultiViews +SymLinksIfOwnerMatch
#    	Order allow,deny
#    	Allow from all
#    </Directory>

    ErrorLog /var/log/apache2/$1-error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog /var/log/apache2/$1-access.log combined
    ServerSignature On

    RewriteEngine on
    # rewrite www to http://$1
    RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
    RewriteRule ^(.*)$ http://%1\$1 [R=301,L]

</VirtualHost>

<VirtualHost *:443>
	ServerName $1
	ServerAlias $1 www.$1
	ServerAdmin webadmin@$1
	
	DocumentRoot /var/www/$1
	<Directory /var/www/$1/>
		Options Indexes FollowSymLinks MultiViews
		#AllowOverride AuthConfig Limit FileInfo Options
    AllowOverride All
		Order allow,deny
		allow from all
	</Directory>

#	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
#	<Directory "/var/www/$1/cgi-bin">
#		AllowOverride None
#		Options ExecCGI -MultiViews +SymLinksIfOwnerMatch
#		Order allow,deny
#		Allow from all
#	</Directory>

    ErrorLog /var/log/apache2/$1-error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog /var/log/apache2/$1-access.log combined

		ServerSignature On
    
		SSLEngine on
    SSLCertificateFile /etc/ssl/private/$1.crt
 
    RewriteEngine on
    # rewrite www to https://$1
    RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
    RewriteRule ^(.*)$ https://%1\$1 [R=301,L]

</VirtualHost>" > /etc/apache2/sites-available/$1 || echo -e "\e[1;31mFAIL\e[0m"

echo -e "running: enable $1 virtualhost\n"
a2ensite $1 || echo -e "\e[1;31mFAIL\e[0m"

echo -e "restart apache2\n"
/etc/init.d/apache2 restart

echo -e "\n===================DONE==================\n"
echo -e "Please read through the above output carefully for failures"
echo -e "Go to http://$1 and finish your wordpress install\n"
echo -e "Be sure to setup DNS!! \n"
echo -e "\n"
echo -e "\n"
echo "Your wordpress configuation"
echo "database username: $db"
echo "database name: $db"
echo "database pass: $pass"
echo "database host: localhost"


