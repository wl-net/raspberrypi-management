#!/bin/bash -e

function prompt() {
  local  __resultvar=$1
  echo -n "${2} "
  local  myresult=''
  read myresult
  eval $__resultvar="'$myresult'"
}

function error() {
  echo "[ERROR]: $1"
  exit 1
}

function info() {
  echo "[INFO]: $1"
}

prompt DEVICE "Please enter the device you want to image:"

if [ ! -e $DEVICE ]; then
  error "$DEVICE could not be found."
fi

prompt reply "Are you sure you want to use $DEVICE?"

function speedtest() {
  info "Performing speed test..."
  sync
  time sudo dd if=/dev/zero of=$DEVICE count=100 bs=1M
  time sync
}

function image() {
  info "Copying image..."
  unzip -p $1 | sudo dd of=$DEVICE bs=1M
  info "Image copied."
}

function imagelist() {
  info "Here is a list of available images"
  ls -1tr *raspbian*.zip
}

function mountdev() {
  sudo mount "${DEVICE}2" "$TMP/"
  sudo mount "${DEVICE}1" "$TMP/boot"
}

function umountdev() {
  sudo umount "$TMP/boot"
  sudo umount "$TMP/"
}

function setuphostname() {
  prompt hostname "Please enter the desired hostname:"
  echo "$hostname" | sudo tee $TMP/etc/hostname >/dev/null
  echo "127.0.0.1	$hostname" | sudo tee -a $TMP/etc/hosts >/dev/null
}

function setupinterfaces() {
  prompt address "Please enter the primary IP address with subnet mask:"  
  prompt routers "Please enter the default gateway"
  prompt dns "Please enter the DNS server"
  echo "interface wlan0
  static ip_address=$address
  static routers=$routers
  static domain_name_servers=$dns" | sudo tee -a $TMP/etc/dhcpcd.conf > /dev/null
}

function setupwireless() {
  prompt ssid "Please enter the SSID of the network you wish to connect to:"
  prompt password "Please enter the password of the network you want to connect to:"
  echo "network={
	ssid=\"$ssid\"
	psk=\"$password\"
	proto=RSN
	key_mgmt=WPA-PSK
	pairwise=CCMP
	auth_alg=OPEN
	disabled=0
}" | sudo tee -a $TMP/etc/wpa_supplicant/wpa_supplicant.conf >/dev/null
  info "Wireless network $ssid created"
}

if [[ $reply =~ ^[Yy]$ ]]; then
  speedtest
  imagelist
  prompt imagepath "Please enter the image you would like to use:"
  image $imagepath
  TMP=$(mktemp -d)
  mountdev
  setuphostname
  setupinterfaces
  setupwireless
  umountdev
fi
