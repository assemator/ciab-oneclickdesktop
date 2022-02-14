
# ciab-oneclick.sh
A one-click script that installs a Selectable Remote Ubuntu Desktop Environment (DE) with HTML5 Web Browser/RDP access.

## Features of this script
* Build Guacamole Server from source.
* Set up Guacamole Web APP.
* Install Tomcat 9, xRDP, Installer Selectable Desktop Environment (DE) and Firefox.
  Selectable DE include:
  - Kubuntu (KDE)
  - Ubuntu (Gnome)
  - Ubuntu-MATE
  - Lubuntu (LXDE)
  - Xubuntu (XFCE)
  - Ubuntu-Budgie (Budgie)
* ciab-oneclick free SSL certificates from Let's Encrypt if Installer chooses **not** to use Let's Encrypt then this script will
  configure NGINX to use *Self-Signed Certificate* so End-Users can still use HTTPS with its additional communications encryption capability.
* You can access your remote desktop from browsers, no need for RDP or VNC software.

## System requirement
* A __freshly installed__ server, with Ubuntu 20.04 LTS 64 bit
* One IPv4 internet accessible interface
* Root access, or sudo user access in **both** the Host/Server/Cloud-instance/VM _**and**_ in the LXD container

## How to use
* Firstly, you need to find a Host/Server/Cloud-instance/VM with Ubuntu 20.04 LTS installed.
* If installing User elects to use Lets-Encrypt you will need a domain name (can be a subdomain) which points to the IP address of your server.
* Then, please run the following commands as a sudo user in the Host/Server/Cloud-instance/VM

```
>  sudo adduser yourID  # answer all the questions to setup your own User Account in both the HOST & container
>  sudo adduser yourID adm
>  sudo adduser yourID sudo
>  sudo mkdir /opt/ciab
>  sudo chown yourID:yourID /opt/ciab
>  sudo chmod 766 /opt/ciab
>  cd /opt/ciab
>  su yourID
>  wget https://github.com/bmullan/ciab-oneclickdesktop/archive/refs/heads/master.zip
>  unzip master.zip
>  setup-ciab-oneclick.sh

```
* The script will guide you through the installation process.
* If you encounter any errors, please check the `oneclick.log` file that's located within the same directory where you download this script.
* Copy/paste between client and server should have been enabled by default.  If you have any problems with copy/paste when using VNC method, please try to run the EnableCopyPaste.sh file on your Desktop.

## Plugins
There is a few plugin scripts/addons available.
* ciab-oneclick change Guacamole "site" LoginID and Password.  

## Frequently Asked Questions (FAQ)

### General

1. Q: Which OS should I use?
* A: This script supports only Ubuntu 20.04 LTS.

2. Q: Should I use my root user or a non-root user to use my desktop?
* A: For RDP, you should always use a non-root user, unless you wish to install some certain software on your desktop.
     To create a non-root user, simply run `adduser USERNAME` in your terminal or SSH.

3. Q: Should I choose to set up NGInX Reverse Proxy and use Let's Encrypt to enable HTTPS/SSL?
* A: NOTE:
     If you have a registered Domain Name pointing to your Host/Server/Cloud-Instance/VM then Select to install the unless you enable SSL (HTTPS) for your Desktop access,
     your Web Browser won't let you cut & paste between the Remote Desktop and your Local computer.

     If you are installing this desktop environment alongside a production environment, you should set up your current webserver software (Apache, Nginx, Litespeed, Caddy, etc.)
     as a reverse proxy of http://127.0.0.1:8080/guacamole and set up SSL for it.

     Uunless you enable HTTPS/SSL for your Desktop access, your browser probably won't let you cut&paste between the remote desktop and your local computer.

     If you are installing this desktop environment alongside a production environment, you should set up your current webserver software (in our case - NGINX)
     as a reverse proxy of http://127.0.0.1:8080/guacamole and set up SSL for it.

4. Q: Are there any security measures that can be taken to make this desktop environment safer?
* A: The End-User's Web Browser will be using an HTTPS/TLS encrypted connection to the Guacamole front-end for our ciab-oneclick Desktop.

     The script sets up the UFW/firewall rules to only allow traffic through port 80 and 443.

     The actual ciab-oneclick installed Desktop runs in an "unprivileged" LXD Ubuntu 20.04 Container on its own non-routable 10.X.X.X private network.
     This 10.X.X.X network is not accessible directly from the Internet
     Only users that "know" the "site" guacamole Username and Password get access to the xRDP Login screen.
     At the xRDP Login screen the user will also have to enter their Ubuntu Desktop User ID and Password.
     Only after entering BOTH sets of UserIDs and Passwords does an End-User get access to their ciab-oneclick installed Ubuntu Desktop

### Installation

5. Q: My installation failed; why?
* A: I am not able to anwser this question unless you provide more details.  Please check the `oneclick.log` file which is located in the same folder where you run this script, and check for any errors.
     Please then check the following questions for an answer or report these errors/logs by opening an 'issue' in this repository.

6. Q: My Nginx installation failed, why?
* A: This is most likely due to you have another webserver installed and running (for example, Apache2).  You need to uninstall all other webserver programs before running this script, or skip the Nginx reverse proxy part of the installation and
     set up reverse proxy manually after the installation.

7. Q: My Let's Encrypt SSL installation failed, why?
* A: One possibility is that you did not enter a valid e-mail address when you asked you to; but most likely, this problem is because __the domain name you are using is not (yet) pointing to the IP address of your server__.
     NOTE:
           To use Lets-Encrypt you must have Port 80 and 8080 open.
           It may take up to 48 hours for DNS changes to propagate throughout the world.
           If you are using Cloudflare DNS, you will need to use the "DNS Only" mode in order to provision a Let's Encrypt SSL; you can otherwise use the free SSL from Cloudflare, and skip the SSL step here instead.
           A very rare case is that if you have provisioned too many Let's Encrypt SSL certificates recently for this domain name, the Let's Encrypt SSL installation may also fail; in this case, please use another domain instead, or wait a couple of days.

### Post-Installation

8. Q: Can I change my Guacamole username and password?
* A: Yes, use the password-update.sh script.

9. Q: My desktop is laggy; can I improve the user experience?
* A: Yes, to some extent.
     You might try decreasing the screen resolution by editting `/etc/guacamole/user-mapping.xml` file.

10. Q: I cannot cut&paste between my server's desktop and my own computer, why?
* A: As mentioned before, you have to set up SSL for your Guacamole; otherwise your browser will not allow you to cut&paste between the two servers.

11. Q: Can I install Software XXX/YYY/ZZZ on this desktop?
* A: Most likely, yes.  With Ubuntu, you can simply google "How to install XXX on ubuntu" and you can usually find a dozen tutorials.

12. Q: Is there a clean way to uninstall everything installed by this script?
* A: Not at this moment but the easiest path would be to:

     Create a new LXD container (note: the following example creates and Ubuntu 20.04 container called cn_name:
          $ lxc launch ubuntu:focal cn_name

     Then install ciab-oneclick in the new LXD container

     You can also Delete the current LXD container ciab-oneclick was installed in:
          $ lxc delete cn_name --force

## References
* Guacamole documentation:  https://guacamole.apache.org/doc/gug/installing-guacamole.html
* LXD documentation: https://linuxcontainers.org/lxd/docs/master/

## Update log
 __Current version: v1.0__

