


WP_CONFIG_DATA=$(cat <<EOF
define('WP_ALLOW_MULTISITE', true);
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true);
define('DOMAIN_CURRENT_SITE', 'EXAMPLE.COM');
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


sudo head -n -3 ./data/wordpress/wp-config.php > wp-config.php
sudo echo "$WP_CONFIG_DATA" >> wp-config.php
sudo tail -n 3 ./data/wordpress/wp-config.php >> wp-config.php
sudo mv wp-config.php ./data/wordpress/wp-config.php

sudo echo "$HT_ACCESS_DATA" >> ./data/wordpress/.htaccess
echo "Now Restart containers using:       docker-compose restart"
