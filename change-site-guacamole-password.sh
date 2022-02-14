#!/bin/bash

#=======================================================================================================
# NOTE:  Execute this Script as SUDO or ROOT .. NOT as a normal UserID
#        Check if user is root or sudo ... if NOT then exit and tell user.
#=======================================================================================================

if ! [ $(id -u) = 0 ]; then echo "Please run this script as either SUDO or ROOT !"; exit 1 ; fi

#=======================================================================================================
# This script will change your Guacamole Web Application Site Login credentials (username and password).
# If Guacamole fails to connect after changing the password, please reboot your server.
#=======================================================================================================
#
function change_passwd
{
	echo 
	echo "You are about to change your Guacamole Site Login credentials."
	sleep 2
	echo "Please input your NEW Site Guacamole Username (alphanumeric only):" 
	read guacamole_username

echo 
	echo "Please input your NEW Site Guacamole Password (alphanumeric only):"
	read guacamole_password_prehash
	echo 
	read guacamole_password_md5 <<< $(echo -n $guacamole_password_prehash | md5sum | awk '{print $1}')
  
	new_username_line="         username=\"$guacamole_username\""
	new_password_line="         password=\"$guacamole_password_md5\""
	old_username_line="$(grep username= /etc/guacamole/user-mapping.xml)"
	old_password_line="$(grep password= /etc/guacamole/user-mapping.xml)"
	echo
	sed -i "s#$old_username_line#$new_username_line#g" /etc/guacamole/user-mapping.xml
	sed -i "s#$old_password_line#$new_password_line#g" /etc/guacamole/user-mapping.xml
	systemctl restart tomcat9 guacd
	echo "Guacamole login credentials successfully changed!"
	echo 
}

change_passwd
