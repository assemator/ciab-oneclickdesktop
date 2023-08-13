#!/bin/bash

#!/bin/bash

#==========================================================================================
#    ciab-onclick Desktop & Browser Access Setup Script v1
#
#    Based on:
#        Github link: https://github.com/Har-Kuun/oneclick
#
#==========================================================================================


#==========================================================================================
# NOTE:  Execute this Script as SUDO or ROOT .. NOT as a normal UserID
#        Check if user is root or sudo ... if NOT then exit and tell user.

if ! [ $(id -u) = 0 ]; then echo "Please run this script as either SUDO or ROOT !"; exit 1 ; fi

#==========================================================================================
# You can change the Guacamole source file download link in this by checking the latest
# Guacamole Version number here:
#
#          https://guacamole.apache.org/releases/ for the latest stable version.
#

#==========================================================================================
# latest version of guacamole as of 2/10/2022 is v1.4.0

GUACAMOLE_VERSION=$(curl -s https://archive.apache.org/dist/guacamole/ | grep -oE '1\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)
GUACAMOLE_DOWNLOAD_LINK="https://archive.apache.org/dist/guacamole/$GUACAMOLE_VERSION/source/guacamole-server-$GUACAMOLE_VERSION.tar.gz"


# By default, this script only works on Ubuntu 20.04 LTS.

OS_CHECK_ENABLED=ON

#==========================================================================================
# ID where our Install files are located

INSTALL_DIR=/opt/ciab

#==========================================================================================
#    Functions start here.
#    Do not change anything below unless you know what you are doing.   #
#==========================================================================================

exec > >(tee -i oneclick.log)
exec 2>&1

function check_OS
{
	if [ -f /etc/lsb-release ] ; then
		cat /etc/lsb-release | grep "DISTRIB_RELEASE=20." >/dev/null
		if [ $? = 0 ] ; then
			OS=UBUNTU20
		else
			say "Sorry, this script only supports Ubuntu 20.04 LTS." red
			echo
			exit 1
		fi
	fi
}

#==========================================================================================
#
function say
{

# This function is a colored version of the built-in "echo."
	echo_content=$1
	case $2 in
		black | k ) colorf=0 ;;
		red | r ) colorf=1 ;;
		green | g ) colorf=2 ;;
		yellow | y ) colorf=3 ;;
		blue | b ) colorf=4 ;;
		magenta | m ) colorf=5 ;;
		cyan | c ) colorf=6 ;;
		white | w ) colorf=7 ;;
		* ) colorf=N ;;
	esac
	case $3 in
		black | k ) colorb=0 ;;
		red | r ) colorb=1 ;;
		green | g ) colorb=2 ;;
		yellow | y ) colorb=3 ;;
		blue | b ) colorb=4 ;;
		magenta | m ) colorb=5 ;;
		cyan | c ) colorb=6 ;;
		white | w ) colorb=7 ;;
		* ) colorb=N ;;
	esac
	if [ "x${colorf}" != "xN" ] ; then
		tput setaf $colorf
	fi
	if [ "x${colorb}" != "xN" ] ; then
		tput setab $colorb
	fi
	printf "${echo_content}" | sed -e "s/@B/$(tput bold)/g"
	tput sgr 0
	printf "\n"
}

#==========================================================================================
#
function determine_system_variables
{
	CurrentUser="$(id -u -n)"
	CurrentDir=$(pwd)
	HomeDir=$HOME
}


#==========================================================================================
#
function get_user_options
{
	echo
	say @B"Please input your 'Site' Guacamole username:" yellow
	read guacamole_username
	echo
	say @B"Please input your 'Site' Guacamole password:" yellow
	read guacamole_password_prehash
	read guacamole_password_md5 <<< $(echo -n $guacamole_password_prehash | md5sum | awk '{print $1}')
	echo

	say @B"Guacamole will use RDP to communicate with server desktop." yellow
	choice_rdpvnc=1

	echo
	if [ $choice_rdpvnc = 1 ] ; then
		say @B"Please choose a screen resolution." yellow
		echo "Choose 1 for 1280x800 (default), 2 to fit your local screen, or 3 to manually configure RDP screen resolution."
		read rdp_resolution_options
		if [ $rdp_resolution_options = 2 ] ; then
			set_rdp_resolution=1;
			if [ $rdp_resolution_options = 3 ] ; then
				echo
				echo "Please type in screen width (default is 1280):"
				read rdp_screen_width_input
				echo "Please type in screen height (default is 800):"
				read rdp_screen_height_input
				if [ $rdp_screen_width_input -gt 1 ] && [ $rdp_screen_height_input -gt 1 ] ; then
					rdp_screen_width=$rdp_screen_width_input
					rdp_screen_height=$rdp_screen_height_input
				else
					say "Invalid screen resolution input." red
					echo
					exit 1
				fi
			else
				# this will be the "default"
				rdp_screen_width=1280
				rdp_screen_height=800
			fi
		fi
		say @B"Screen resolution successfully configured." green
	fi
	echo
	say @B"Would you like to set up Nginx Reverse Proxy?" yellow
	say @B"Please note that if you want to copy or paste text between the server and your computer, you MUST set up an Nginx Reverse Proxy AND an SSL certificate.  You can set it up later manually though." yellow
	echo "Please type [Y/n]:"
	read install_nginx
	if [ "x$install_nginx" != "xn" ] && [ "x$install_nginx" != "xN" ] ; then
		echo
		say @B"Please tell me your domain name (e.g., desktop.ciab):" yellow
		read guacamole_hostname
		echo
		echo
		echo "Would you like to install a free Let's Encrypt certificate for domain name ${guacamole_hostname}? [Y/N]"
		say @B"Please point your domain name to this server IP BEFORE continuing!" yellow
		echo "Type Y if you are sure that your domain is now pointing to this server IP."
		read confirm_letsencrypt
		echo
		if [ "x$confirm_letsencrypt" = "xY" ] || [ "x$confirm_letsencrypt" = "xy" ] ; then
			echo "Please input an e-mail address:"
			read le_email
		fi
	else
		say @B"OK, Nginx will be installed with a 'Self-Signed Certificate'..." yellow

		# Set NGINX to use a "Self-SignedCertificate"

		$PWD/setup-nginx.sh

	fi

	echo
	say @B"Desktop Environment installation starting... " green
	sleep 3
}

function install_guacamole_ubuntu
{
	echo
	say @B"Setting up dependencies..." yellow
	echo
	apt-get update && apt-get upgrade -y
	apt-get -y install wget curl zip unzip tar perl expect build-essential libcairo2-dev libpng-dev libtool-bin libossp-uuid-dev freerdp2-dev 
	apt-get -y libssh2-1-dev libtelnet-dev libwebsockets-dev libpulse-dev libvorbis-dev libwebp-dev libssl-dev libpango1.0-dev libswscale-dev 
	apt-get -y libavcodec-dev libavutil-dev libavformat-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user 
	apt-get -y fonts-ipafont-gothic fonts-unfonts-core
	apt-get -y install libjpeg-turbo8-dev 

	wget $GUACAMOLE_DOWNLOAD_LINK
	tar zxf guacamole-server-${GUACAMOLE_VERSION}.tar.gz
	rm -f guacamole-server-${GUACAMOLE_VERSION}.tar.gz
	cd $CurrentDir/guacamole-server-$GUACAMOLE_VERSION
	echo "Start building Guacamole Server from source..."
	./configure --with-init-dir=/etc/init.d
	if [ -f $CurrentDir/guacamole-server-$GUACAMOLE_VERSION/config.status ] ; then
		say @B"Dependencies met!" green
		say @B"Compiling now..." green
		echo
	else
		echo
		say "Missing dependencies." red
		echo "Please check log, install required dependencies, and run this script again."
		echo
		exit 1
	fi
	sleep 2
	make
	make install
	ldconfig
	echo "Trying to start Guacamole Server for the first time..."
	echo "This can take a while..."
	echo 
	systemctl daemon-reload
	systemctl start guacd
	systemctl enable guacd
	ss -lnpt | grep guacd >/dev/null
	if [ $? = 0 ] ; then
		say @B"Guacamole Server successfully installed!" green
		echo 
	else 
		say "Guacamole Server installation failed." red
		say @B"Please check the log for reasons." yellow
		exit 1
	fi
}


function install_guacamole_web
{
	echo
	echo "Start installaing Guacamole Web Application..."
	cd $CurrentDir
	mv guacamole-$GUACAMOLE_VERSION.war /var/lib/tomcat9/webapps/guacamole.war
i
	systemctl restart tomcat9 guacd

	echo
	say @B"Guacamole Web Application successfully installed!" green
	echo
}

function configure_guacamole_ubuntu
{
	echo
	mkdir /etc/guacamole/
	cat > /etc/guacamole/guacamole.properties <<END
guacd-hostname: localhost
guacd-port: 4822
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping: /etc/guacamole/user-mapping.xml
END
	if [ $choice_rdpvnc = 1 ] ; then
		if [ $set_rdp_resolution = 0 ] ; then
			cat > /etc/guacamole/user-mapping.xml <<END
<user-mapping>
    <authorize
         username="$guacamole_username"
         password="$guacamole_password_md5"
         encoding="md5">
       <connection name="default">
         <protocol>rdp</protocol>
         <param name="hostname">localhost</param>
         <param name="port">3389</param>
       </connection>
    </authorize>
</user-mapping>
END
		else
			cat > /etc/guacamole/user-mapping.xml <<END
<user-mapping>
    <authorize
         username="$guacamole_username"
         password="$guacamole_password_md5"
         encoding="md5">
       <connection name="default">
         <protocol>rdp</protocol>
         <param name="hostname">localhost</param>
         <param name="port">3389</param>
		 <param name="width">$rdp_screen_width</param>
		 <param name="height">$rdp_screen_height</param>
       </connection>
    </authorize>
</user-mapping>
END
		fi
	fi
	systemctl restart tomcat9 guacd
	say @B"Guacamole successfully configured!" green
	echo
}


function install_rdp
{
	echo
	echo "Start install od Selectable Desktop, Firefox Web Browser, and xRDP server..."

	if [ "$OS" = "UBUNTU18" ] || [ "$OS" = "UBUNTU20" ] ; then
		say @B"Please note that if you are asked to configure GDM or LightDM during this step, Choose GDM is usually best" yellow
		echo 
		echo "Press Enter to continue."
		read catch_all
		echo
	fi

	echo
	echo
	echo "====={ CIAB Desktop Environment Chooser }======================================================================="
	echo
	echo " Pick the Desktop Environment you want to install in CIAB."
	echo
	echo

	PS3=' Please enter your choice of Desktop Environment to install... '

	LIST_DE_CHOICES="KDE LXDE GNOME MATE XFCE BUDGIE"

	select OPT in $LIST_DE_CHOICES
	do

		if [ $OPT = "KDE" ] &> /dev/null
		then
			echo
			echo "---------------------------------"
			echo "You chose the Kubuntu KDE Desktop"
			echo
			sudo apt-get install kubuntu-desktop -y
			break

		elif [ $OPT = "LXDE" ] &> /dev/null
		then
			echo
			echo "----------------------------------"
			echo "You chose the Lubuntu LXDE Desktop"
			echo
			sudo apt-get install lubuntu-desktop -y
			break

		elif [ $OPT = "GNOME" ] &> /dev/null
		then
			echo
			echo "----------------------------------"
			echo "You chose the Ubuntu Gnome Desktop"
			echo
			sudo apt-get install ubuntu-desktop -y
			break

		elif [ $OPT = "MATE" ] &> /dev/null
		then
			echo
			echo "---------------------------------"
			echo "You chose the Ubuntu MATE Desktop"
			echo

			sudo apt install ubuntu-mate-desktop -y

			# Create a flag file to indicate MATE was chosen for the Desktop Environment
			# So when we install XRDP we will know whether we need to patch the
			# /usr/share/applications/caja.desktop

			sudo touch $PWD/fix-mate

			break

		elif [ $OPT = "XFCE" ] &> /dev/null
		then
			echo
			echo "----------------------------------"
			echo "You chose the Xubuntu XFCE Desktop"
			echo
			sudo apt-get install xubuntu-desktop -y
			break

		elif [ $OPT = "BUDGIE" ] &> /dev/null
		then
			echo
			echo "-----------------------------------"
			echo "You chose the Ubuntu Budgie Desktop"
			echo
			sudo apt install ubuntu-budgie-desktop -y

			# create a flag file to indicate BUDGIE was chosen for the Desktop Environment
			# So when we install XRDP we will know whether we need to patch /etc/xrdp/startwm.sh
			# See - CIAB Installation PDF in Errata section at the end.

			sudo touch $PWD/fix-budgie

			break

		fi

	done
	#END

	sudo systemctl set-default graphical.target
	apt-get install firefox xrdp -y

	say @B"Desktop, browser, and XRDP server successfully installed." green
	echo "Starting to configure XRDP server..."
	sleep 2
	echo

	sudo chmod +x /etc/xrdp/startwm.sh
	sudo systemctl enable xrdp
	sudo systemctl restart xrdp
	sleep 5
	echo "Waiting to start XRDP server..."
	sudo systemctl restart guacd
	cat > /etc/systemd/system/restartguacd.service <<END
[Unit]
Descript=Restart GUACD

[Service]
ExecStart=/etc/init.d/guacd start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

END
	systemctl daemon-reload
	systemctl enable restartguacd
	ss -lnpt | grep xrdp > /dev/null
	if [ $? = 0 ] ; then
		ss -lnpt | grep guacd > /dev/null
		if [ $? = 0 ] ; then
			say @B"xRDP and Desktop successfully configured!" green
		else 
			say @B"xRDP and Desktop successfully configured!" green
			sleep 3
			systemctl start guacd
		fi
		echo 
	else
		say "XRDP installation failed!" red
		say @B"Please check the above log for reasons." yellow
		exit 1
	fi
}


function display_license
{
	echo
	echo '*******************************************************************'
	echo '* ciab-oneclick Desktop, xRDP w/Audio, Browser Setup Script       *'
	echo '*                                                                 *'
	echo '*       Version 1.0                                               *'
	echo '*                                                                 *'
	echo '*       Based on:                                                 *'
	echo '*       https://github.com/Har-Kuun/oneclick               *'
	echo '*******************************************************************'
	echo
}

function install_reverse_proxy
{
	echo
	say @B"Setting up Nginx reverse proxy..." yellow
	sleep 2

	apt-get install nginx certbot python3-certbot-nginx -y

	say @B"Nginx successfully installed!" green
	cat > /etc/nginx/conf.d/guacamole.conf <<END
server {
        listen 80;
        listen [::]:80;
        server_name $guacamole_hostname;

        access_log  /var/log/nginx/guac_access.log;
        error_log  /var/log/nginx/guac_error.log;

        location / {
                    proxy_pass http://127.0.0.1:8080/guacamole/;
                    proxy_buffering off;
                    proxy_http_version 1.1;
                    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                    proxy_set_header Upgrade \$http_upgrade;
                    proxy_set_header Connection \$http_connection;
                    proxy_cookie_path /guacamole/ /;
        }

}
END
	sudo systemctl reload nginx
	if [ "x$confirm_letsencrypt" = "xY" ] || [ "x$confirm_letsencrypt" = "xy" ] ; then
		certbot --nginx --agree-tos --redirect --hsts --staple-ocsp --email $le_email -d $guacamole_hostname
		echo
		if [ -f /etc/letsencrypt/live/$guacamole_hostname/fullchain.pem ] ; then
			say @B"Congratulations! Let's Encrypt SSL certificate installed successfully!" green
			say @B"You can now access your desktop at https://${guacamole_hostname}!" green
		else
			say "Oops! Let's Encrypt SSL certificate installation failed." red
			say @B"Please manually try \"certbot --nginx --agree-tos --redirect --hsts --staple-ocsp --email $le_email -d $guacamole_hostname\"." yellow
			say @B"You can now access your desktop at http://${guacamole_hostname}!" green
		fi
	else
		say @B"Let's Encrypt certificate not installed! If you would like to install a Let's Encrypt certificate later, please manually run \"certbot --nginx --agree-tos --redirect --hsts --staple-ocsp -d $guacamole_hostname\"." yellow
		say @B"You can now access your desktop at http://${guacamole_hostname}!" green
	fi
	say @B"Your Guacamole username is $guacamole_username and your Guacamole password is $guacamole_password_prehash." green
}

function main
{
	display_license
	if [ "x$OS_CHECK_ENABLED" != "xOFF" ] ; then
		check_OS
	fi
	echo "This script will install a Selectable Desktop Environment (DE), xRDP w/Audio, Firefox HTML5 web Browser access."
	echo
	say @B"This environment requires at least 1 GB of RAM." yellow
	echo
	echo "Would you like to proceed? [Y/N]"
	read confirm_installation
	if [ "x$confirm_installation" = "xY" ] || [ "x$confirm_installation" = "xy" ] ; then
		determine_system_variables
		get_user_options
		install_guacamole_ubuntu
		install_guacamole_web
		configure_guacamole_ubuntu
		install_rdp

		if [ "x$install_nginx" != "xn" ] && [ "x$install_nginx" != "xN" ] ; then

			#=================================================================================
			# Installer selected to use NGINX w a Lets-Encrypt signed Certificate

			install_reverse_proxy

		else

			#=================================================================================
			# Install NGINX to use a "self-signed-certificate" so the End-User can still
			# use HTTPS and its encryption of the web browser communcations link to the
			# ciab-onclick selected Desktop

			sudo $PWD/setup-nginx.sh

			#=================================================================================
			# Enable xRDP Audio-Redirection so audio works in the Desktop

			sudo $PWD/setup-xrdp-audio.sh

			say @B"You can now access your desktop at https://$(curl -s icanhazip.com)/guacamole!" green
			say @B"Your Guacamole username is $guacamole_username and your password is $guacamole_password_prehash." green
		fi
		if [ $choice_rdpvnc = 1 ] ; then
			echo
			say @B"Note that after entering Guacamole using the above Guacamole credentials, you will be asked to input your Ubuntu Desktop Username and Password in the 'xRDP panel', which is NOT the ciab-oneclick 'Site' Username and Password above.  Please use the default Xorg as session type." yellow
		fi
	fi
	echo
}

#==============================================================
#
#               The MAIN function starts here.
#
#==============================================================

main

exit 0
