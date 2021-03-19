# [<img src="https://github.com/tmiland/csf/raw/master/img/csf_firewall.png?sanitize=true" height="64" width="128">](https://github.com/tmiland/csf/raw/master/img/csf_firewall.png?sanitize=true) ConfigServer Security & Firewall (csf)
================================

Install ConfigServer Security & Firewall (csf)

Installs all dependencies using apt or yum

Tested on:
* CentOS 8
* Debian 10
* Fedora 33
* Ubuntu 18.10

Default temp dir is ```/tmp/csf```, this can be changed in install script.

By default, the installer logs into ```$TMP/install.log``` and ```$TMP/error.log```. Check these for further info about the installation process.

## Dependencies
* Package manager (apt or yum)
* HTTP Client (curl, wget or fetch)
* TAR executable
* Perl
* Perl modules: (Debian/Ubuntu: ```libwww-perl liblwp-protocol-https-perl libgd-graph-perl```, RHEL: ```perl-libwww-perl.noarch perl-LWP-Protocol-https.noarch perl-GDGraph```)

Dependencies will be installed during the progress, but installing them on your own is advised.

## Installation

```bash
$ wget https://github.com/tmiland/csf/raw/master/csf_installer.sh
$ chmod +x csf_installer.sh
$ ./csf_installer.sh install
```
Or directly

```bash
$ curl -sSL https://github.com/tmiland/csf/raw/master/csf_installer.sh install | bash
```

* Webmin module will be installed automatically if Webmin is installed.
  * **Not currently tested**
  Script command which will run: ```/usr/share/webmin/install-module.pl /usr/local/csf/csfwebmin.tgz```
* For manually installing the module: Log in to Webmin and install the CSF module from /usr/local/csf/csfwebmin.tgz

### Offline installation

Clone this repository or download ```csf_installer.sh``` and download the following file manually into the install script path:

[CSF Archive](https://download.configserver.com/csf.tgz)

Run ```csf_installer.sh install```

## Uninstallation

* Run ```csf_installer.sh uninstall```

You may find some error messages in the log about ```apf```. If you don't know what apf is or you don't have apf installed just ignore these messages.

For further info check [Official website](http://configserver.com/cp/csf.html) or [Installation notes](https://download.configserver.com/csf/install.txt)

[changelog](https://download.configserver.com/csf/changelog.txt)

## Credits

Forked from [installation](https://github.com/installation/csf)

## Donations 
- [PayPal me](https://paypal.me/milanddata)
- [BTC] : 33mjmoPxqfXnWNsvy8gvMZrrcG3gEa3YDM

## Web Hosting

Sign up for web hosting using this link, and receive $100 in credit over 60 days.

[DigitalOcean](https://m.do.co/c/f1f2b475fca0)

#### Disclaimer 

*** ***Use at own risk*** ***

### License

[![MIT License Image](https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/MIT_logo.svg/220px-MIT_logo.svg.png)](https://github.com/tmiland/csf/blob/master/LICENSE)

[MIT License](https://github.com/tmiland/csf/blob/master/LICENSE)
