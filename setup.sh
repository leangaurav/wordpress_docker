set -e

echo "Step-1 : Moving old docker-compose.yml to .prev. Creating new!"
mv  docker-compose.yml docker-compose.yml.prev | true
cp conf/docker-compose.yml .

DOMAINS=""
STAGING=false

for i in "$@"
do
case $i in
	-t)
		STAGING=true
		;;
	-d=*)
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


echo "Step-2: Setting Uid: " $U_ID "\t Gid: " $G_ID
sed -i "s/P_ID/$U_ID/g" ./docker-compose.yml
sed -i "s/G_ID/$G_ID/g" ./docker-compose.yml



if [ -z "$DOMAIN" ]
then
	echo "Missing Domain(Specify like -p=example.com)"
	exit 0
else
	echo "Step-3 : Updating primary and sub domains"
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



echo "Step-4 : Setting Test status: " $STAGING
sed -i "s/STAGING_VAL/$STAGING/g" ./docker-compose.yml



echo "Step-5 : Checking old ontainers (wait 10 sec)"
if output=$(docker ps -aq) && [ -z "$output" ]; then
	echo "No Old Containers found!"
else
	echo "Existing running containers found! Cleaning(wait 10 sec)"
	docker stop $(docker ps -q) | true
	docker rm $(docker ps -aq) | true
	sleep 10
fi

echo "Step-6(Last) : Checking for multi-domain"


if [ -z "$DOMAINS" ]
then
        echo "No Extra domains sepecified\n Complete !!"
else
        echo "Extra domains specified. Generating multisite script: setupMultisite.sh"
	rm  setupMultisite.sh | true
	cp conf/setupMultisite.sh .
	sed -i "s/EXAMPLE.COM/$DOMAIN/g" ./setupMultisite.sh
fi


echo "Complete! now run:   docker-compose up -d"
