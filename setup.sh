DOMAINS=""

for i in "$@"
do
case $i in
	-t)
		STAGING=true
		;;
	-p=*)
		DOMAIN="${i#*=}"
		;;
	*)
		if [ -z "$DOMAINS" ]
		then
			DOMAINS="${i#*=}"
		else
			DOMAINS="$DOMAINS,${i#*=}"
		fi
		;;
esac
done

U_ID=`id -u`
G_ID=`id -g`
STAGING=false


echo "Setting Uid: " $U_ID "\t Gid: " $G_ID
sed -i "s/P_ID/$U_ID/g" ./docker-compose.yml
sed -i "s/G_ID/$G_ID/g" ./docker-compose.yml



if [ -z "$DOMAIN" ]
then
	echo "Missing Domain(Specify like -p=example.com)"
	exit 0
else
	echo " Primary Domain: " $DOMAIN "\n Sub Domains: " $DOMAINS
	sed -i "s/EXAMPLE.COM/$DOMAIN/g" ./docker-compose.yml
fi
	
if [ -z "$DOMAINS" ]
then
	echo "No Extra domains sepecified"
else
	echo "Adding Sub domains : " $DOMAINS
        EXTRA_DOMAINS="- EXTRA_DOMAINS=$DOMAINS"
        sed -i "s/#EXTRA_DOMAINS/$EXTRA_DOMAINS/g" ./docker-compose.yml
fi



echo "Setting Test status: " $STAGING
sed -i "s/STAGING_VAL/$STAGING/g" ./docker-compose.yml



echo "Cleaning any old docker containers (wait 4 sec)"
sudo docker rm $(docker ps -aq)
sleep 4



echo "Starting docker containers(waiting 40 sec)"
sudo docker-compose up -d
sleep 40




WP_CONFIG_DATA=$(cat <<EOF
define('WP_ALLOW_MULTISITE', true);
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true);
define('DOMAIN_CURRENT_SITE', "$DOMAIN");
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1);
define('BLOG_ID_CURRENT_SITE', 1);
EOF
)

HT_ACCESS_DATA=`cat <<EOF
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]

# add a trailing slash to /wp-admin
RewriteRule ^wp-admin$ wp-admin/ [R=301,L]

RewriteCond %{REQUEST_FILENAME} -f [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^(wp-(content|admin|includes).*) $1 [L]
RewriteRule ^(.*\.php)$ $1 [L]
RewriteRule . index.php [L]
</IfModule>
# END WordPress
EOF
`

if [ -z "$DOMAINS" ]
then
        echo "No Extra domains sepecified\n Complete !!"
else
        echo "Extra domains specified. Updating for multisite"
	sudo echo "$WP_CONFIG_DATA" >> ./data/wordpress/wp-config.php
	sudo rm -rf ./data/wordpress/.htaccess
	sudo echo "$HT_ACCESS_DATA" >> ./data/wordpress/.htaccess
	echo "Restarting docker containers(wait 5 sec)"
	sudo docker-compose restart
fi
