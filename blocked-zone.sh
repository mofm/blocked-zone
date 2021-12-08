#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# display date
date

# Serial yyyymmddnn
SERIAL=$(date +"%Y%m%d")01

# Set tempfiles
domains=$(mktemp)
zone_file=$(mktemp)

# Define local black lists
# Uncomment if you have no local files
blacklist="blacklist"

# StevenBlack GitHub Hosts
# Uncomment ONE line containing the filter you want to apply
# See https://github.com/StevenBlack/hosts for more combinations
wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts

# Filter out localhost and broadcast
cat StevenBlack-hosts | grep '^0.0.0.0' | egrep -v '127.0.0.1|255.255.255.255|::1' | cut -d " " -f 2 | egrep -v '^0.0.0.0' >> $domains

# Add local blacklist
if [ -f $blacklist ]
then
    cat $blacklist >> $domains
fi

# Create Zone File
cat >> $zone_file << EOL
\$TTL	86400
@	IN	SOA	localhost. root.localhost. (
			 ${SERIAL}	; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
;
@	IN	NS	localhost.
EOL

# Create A record for blacklist domain 
while read line; do
	dots=$(echo $line | grep -o "\." | wc -l)
	if [[ $dots -eq 1 ]]; then
		echo "*.$line	IN	A	0.0.0.0" >> $zone_file
	else
		echo "$line	 IN	A	0.0.0.0" >> $zone_file
	fi
done < $domains

# Copy temp file to right directory
# This is for Gentoo, might differ on other systems
cp $zonefile /var/bind/pri/db.blocked.local
chown named:named /var/bind/pri/db.blocked.local

# Reload bind
rndc reload

# Finish
echo -e 'done\n\n'
