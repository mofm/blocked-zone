# Block ads and malware via BIND9 RPZ

## Installation on Ubuntu 20.04 LTS

* Run following command to install BIND 9 on Ubuntu 20.04

```sh
sudo apt update
sudo apt install bind9 bind9utils bind9-dnsutils
```

* Configurations for recursive DNS resolver with RPZ(responsive policy zone)

	- To enable recursion service, edit '/etc/bind/named.conf.options':

	````
	// hide version number from clients for security reasons.
 	version "not currently available";

	// optional - BIND default behavior is recursion
 	recursion yes;

 	// provide recursion service to trusted clients only
	allow-recursion { 127.0.0.1; 192.168.0.0/24; 10.10.10.0/24; };

	// disallow zone transfer
	allow-transfer { none; };

	// enable the query log
	querylog yes;

	//enable response policy zone.
	response-policy {
		zone "blocked.local";
	};
	````

	- Add RPZ zone in '/etc/bind/named.conf.local':

	````
	zone "blocked.local" {
	    type master;
	    file "/etc/bind/db.blocked.local";
	    allow-query { localhost; };
	    allow-transfer { localhost; };
	};
	````

	- add following lines in '/etc/bind/named.conf' to use separate log file for RPZ(recommended):

	````
	logging {
	    channel blockedlog {
	        file "/var/log/named/blocked-zone.log" versions unlimited size 100m;
	        print-time yes;
	        print-category yes;
	        print-severity yes;
	        severity info;
	    };
	    category rpz { blockedlog; };
	};
	````

	If '/var/log/named/' directory doesn't exist, create it and make bind as the owner

	```sh
	sudo mkdir /var/log/named/
	sudo chown bind:bind /var/log/named/ -R
	```

* Add blocked zone file with the blocked-zone.sh script.

	- first, clone this repository:

	```sh
	git clone https://github.com/mofm/blocked-zone.git
	```

	- If there is domain(s) you want to block, you can add it to the blacklist file.

	- execute the blocked-zone.sh script(this script downloads StevenBlack host file and then creates RPZ zone file):

	```sh
	sudo bash blocked-zone.sh
	```

* Check configurations and service:

```sh
sudo named-checkconf
sudo named-checkzone rpz /etc/bind/db.blocked.local
```

If no problem, restart and enable bind9 service;

```sh
sudo systemctl restart bind9
sudo systemctl enable bind9
```

* Test:
	-  You can run the dig command on the BIND server to see if RPZ is working:

	```sh
	dig A adskeeper.com @127.0.0.1
	```

	- You can also check '/var/log/named/blocked-zone.log' for query log:

	```sh
	sudo tail /var/log/named/blocked-zone.log
	```

* READY, you can add this BIND9 host IP address to your host(s).

## Optional
- You can add cronjob for schedule update
- You can change the URL to StevenBlack GitHub Hosts in 'blocked-zone.sh'

