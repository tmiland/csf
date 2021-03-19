#!/usr/bin/env bash

# Script to install ConfigServer Security & Firewall
# Author: Márk Sági-Kazár (sagikazarmark@gmail.com)
# This script installs CSF on several Linux distributions with Webmin.
# https://github.com/installation/csf
#
# Modified by: Tommy Miland (@tmiland)
# https://github.com/tmiland/csf
#------------------------------------------------------------------------------#
#
# MIT License
#
# Copyright (c) 2021 Tommy Miland
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#------------------------------------------------------------------------------#
## Uncomment for debugging purpose
#set -o errexit
#set -o pipefail
#set -o nounset
#set -o xtrace
# Variable definitions
DIR=$(cd "$(dirname $0)" && pwd)
SCRIPT_FILENAME=$(basename "$0")
NAME="ConfigServer Security & Firewall"
SLUG="csf"
DEPENDENCIES=("perl" "tar")
TMP="/tmp/$SLUG"
INSTALL_LOG="$TMP/install.log"
ERROR_LOG="$TMP/error.log"

## Checking root access
if [[ "$EUID" != 0 ]]; then
  echo -e "This action needs root permissions."
  echo -e "Please enter your root password...";
  cd "$DIR" || exit
  su -s "$(which bash)" -c "./$SCRIPT_FILENAME $1"
  cd - > /dev/null || exit
  exit 0; 
fi

# Cleaning up
rm -rf $TMP
mkdir -p $TMP
cd $TMP || exit
chmod 777 $TMP

# Function definitions

## Echo colored text
e() {
  local color="\033[${2:-34}m"
  local log="${3:-$INSTALL_LOG}"
  echo -e "$color$1\033[0m"
  log "$1" "$log"
}

## Exit error
ee() {
  local exit_code="${2:-1}"
  local color="${3:-31}"

  has_dep "dialog"
  [ $? -eq 0 ] && clear
  e "$1" "$color" "$ERROR_LOG"
  exit $exit_code
}

## Log messages
log() {
  local log="${2:-$INSTALL_LOG}"
  echo "$1" >> "$log"
}

## Install required packages
install() {
  [ -z "$1" ] && { e "No package passed" 31; return 1; }

  e "Installing package: $1"
  ${install[1]} "$1" >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Installing $1 failed"
  e "Package $1 successfully installed"

  return 0
}

## Check installed package
check() {
  [ -z "$1" ] && { e "No package passed" 31; return 2; }

  [ "$(which "$1" 2> /dev/null)" ] && return 0

  case ${install[2]} in
    dpkg )
      ${install[3]} -s "$1" &> /dev/null
      ;;
    rpm )
      ${install[3]} -qa | grep "$1"  &> /dev/null
      ;;
  esac
  return $?
}

## Add dependency
dep() {
  has_dep "$1"
  #if [ ! -z "$1" -a $? -eq 1 ]; then
	# Shellcheck complained about the above line (https://github.com/koalaman/shellcheck/wiki/SC2166)
	if [ ! -z "$1" ] && [ $? -eq 1 ]; then
    DEPENDENCIES+=("$1")
    return 0
  fi
  return 1
}

## Dependency is added or not
has_dep() {
  for dep in "${DEPENDENCIES[@]}"; do [ "$dep" == "$1" ] && return 0; done
  return 1
}

## Install dependencies
install_deps() {
  e "Checking dependencies..."
  for dep in "${DEPENDENCIES[@]}"; do
    check "$dep"
    [ $? -eq 0 ] || install "$dep"
  done
}

## Download required file
download() {
  [ -z "$1" ] && { e "No package passed" 31; return 1; }

  local text="${2:-files}"
  e "Downloading $text"
  $download "$1" >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Downloading $text failed"
  e "Downloading $text finished"
  return 0
}

# Disabled for systemd
## Install init script
# init() {
# 	[ -z "$1" ] && { e "No init script passed" 31; return 1; }
#
# 	$init "$1" >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Error during init"
# 	return 0
# }

## Cleanup
cleanup() {
  has_dep "dialog"
  [ $? -eq 0 ] && clear
  e "Cleaning up"
  cd $TMP 2> /dev/null || return 1
	# shellcheck disable=SC2038
  find * -not -name '*.log' | xargs rm -rf
}

# CTRL_C trap
ctrl_c() {
  echo
  cleanup
  e "Installation aborted by user!" 31
}
trap ctrl_c INT

csf_install() {
  # Basic checks

  ## Check for wget or curl or fetch
  e "Checking for HTTP client..."
  if [ "$(which curl 2> /dev/null)" ]; then
    download="$(which curl) -s -O"
  elif [ "$(which wget 2> /dev/null)" ]; then
    download="$(which wget) --no-certificate"
  elif [ "$(which fetch 2> /dev/null)" ]; then
    download="$(which fetch)"
  else
    dep "wget"
    download="$(which wget) --no-certificate"
    e "No HTTP client found, wget added to dependencies" 31
  fi

  ## Check for package manager (apt or yum)
  e "Checking for package manager..."
  if [ "$(which apt-get 2> /dev/null)" ]; then
    install[0]="apt"
		# shellcheck disable=SC2140
    install[1]="$(which apt-get) -o Dpkg::Progress-Fancy="1" install -qq"
  elif [ "$(which yum 2> /dev/null)" ]; then
    install[0]="yum"
    install[1]="$(which yum) install -y -q"
  else
    ee "No package manager found."
  fi

  ## Check for package manager (dpkg or rpm)
  if [ "$(which dpkg 2> /dev/null)" ]; then
    install[2]="dpkg"
    install[3]="$(which dpkg)"
  elif [ "$(which rpm 2> /dev/null)" ]; then
    install[2]="rpm"
    install[3]="$(which rpm)"
  else
    ee "No package manager found."
  fi

	# Disabled for systemd
  ## Check for init system (update-rc.d or chkconfig)
  # e "Checking for init system..."
  # if [ "$(which update-rc.d 2> /dev/null)" ]; then
  # 	init="$(which update-rc.d)"
  # elif [ "$(which chkconfig 2> /dev/null)" ]; then
  # 	init="$(which chkconfig) --add"
  # else
  # 	ee "Init system not found, service not started!"
  # fi

  # Adding dependencies
  case ${install[2]} in
    dpkg )
      dep "libwww-perl"
      dep "liblwp-protocol-https-perl"
      dep "libgd-graph-perl"
      ;;
    rpm )
      dep "perl-libwww-perl.noarch"
      dep "perl-LWP-Protocol-https.noarch"
      dep "perl-GDGraph"
      ;;
  esac

  install_deps

  # Fedora 17 fix
  #[ -d "/etc/cron.d" ] || mkdir "/etc/cron.d"

  if [ -f $DIR/csf.tgz ]; then
    cp -r $DIR/csf.tgz $TMP
  else
    download https://download.configserver.com/csf.tgz "CSF files"
  fi
  tar -xzf csf.tgz >> $INSTALL_LOG 2>> $ERROR_LOG

	VER=$(cat $TMP/csf/changelog.txt | sed -n '3 s/[^0-9.]*\([0-9.]*\).*/\1/p')
  e "Installing $NAME $VER"
	
  cd csf || exit
  sh install.sh >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Installing $NAME $VER failed"

  e "Removing APF"
  sh /usr/local/csf/bin/remove_apf_bfd.sh >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Removing APF failed"

  e "Checking installation"
  perl /usr/local/csf/bin/csftest.pl >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Test failed"

	systemctl enable csf lfd >> $INSTALL_LOG 2>> $ERROR_LOG || ee "enable failed"
	systemctl start csf >> $INSTALL_LOG 2>> $ERROR_LOG || ee "start failed"
	systemctl status csf >> $INSTALL_LOG 2>> $ERROR_LOG || ee "status failed"

  if [[ -f /usr/bin/webmin ]]; then
    e "Installing Webmin module"
    /usr/share/webmin/install-module.pl /usr/local/csf/csfwebmin.tgz >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Webmin module install failed"
  fi

  cleanup

  if [ -s $ERROR_LOG ]; then
    e "Error log is not empty. Please check $ERROR_LOG for further details." 31
  fi

  e "Installation done."
	e "For instructions, see readme: https://download.configserver.com/csf/readme.txt"
}

uninstall() {
	cd /etc/csf || exit
	sh uninstall.sh
	e "Uninstallation done."
	cleanup
}

case "$1" in
  --install|-i)
    csf_install
    ;;
  --uninstall|-u)
    uninstall
    ;;
  *)
    echo "$0 {--install|-i|--uninstall|-u}"
    ;;
esac
