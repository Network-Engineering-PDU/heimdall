#!/bin/bash

yes_or_no () {
	while true; do
		read -p "$* [y/n]: " yn

		case $yn in
		[Yy]*) return 0  ;;
		[Nn]*) return  1 ;;
		esac
	done
}

read_config_ssh() {
	read -p "Port: " port
	config_ssh $port
}

config_ssh () {

	IPADDR="52.49.74.221"
	port=$1

	re='^[0-9]+$'
	if ! [[ $port =~ $re ]] ; then
		echo "Wrong port" >&2; exit 1
	fi

	if [ $port -lt 43022 ]; then
		echo "Wrong port" >&2; exit 1
	fi

	mkdir -p $HOME/.ssh
	chmod 700 $HOME/.ssh

	cp $files_dir/tunnel.pem $HOME/.ssh/tunnel.pem

	chmod 600 $HOME/.ssh/tunnel.pem

	cat << EOF > $HOME/ssh_config
run_autossh=1
ssh_user=guest
ssh_ip=$IPADDR
ssh_port=$port
ssh_key=/home/root/.ssh/tunnel.pem
EOF

	ssh-keygen -R $IPADDR 2>/dev/null 1>/dev/null

	cat << EOF >> $HOME/.ssh/known_hosts
$IPADDR ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFN3M+CkKhhn3YdzRNVMbUp+SOC4y9NN1S1xBn5FN2kHrJTrpw4ir05Z9Y8o112LQIqYBCfkwtd2yP5R/yqvVf8=
EOF

	PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDk/9onf8CLBm2nxmHruD76cODodcWi1ckWzpNVfxyyy43oQ1yF1jaiP/QvBQJSKTip+lv/JYagfPyLWiGTs7nl8SXE8TYaU6s96BMxtE0HdO85Sy+p5ORYyMDOJuvS1d1hhku5lAkMXfL1UdIIJSzOYhhGJUvSySnOt6xpN0y3IntxuB9/ups2WsvMvhvDn3gZH88hHqPEtVgnQcmh3SGfpmVjlnWLPB02PQNHPHeuVnljPYaSU45iG4zo2g8sNPue7TYp02vaiksc6ZnNSANqUTTKYUNnadOwdqQ80r6eUu7JF99hkCFjvanoC0h8k2TNC3SrpENgPOsueWTe723mNF6cy7ldnkSKdrZhxqN9fcSNmTW9NCBYR4qHMPaq16fzBhlO8hMUknUnspvRXUHGSwY/7DyehXiSWnGvnV5Hxr1rvPn/gNrAvpzbDlO3sCRbbhUPGzaoPdXrxJ9FnCUtzpOSWvZRyyTJyUblUodTYXLorL5FjW075pwkQBOXTK8= heimdall_key"

	touch $HOME/.ssh/authorized_keys
	grep -qxF "$PUB_KEY" $HOME/.ssh/authorized_keys || echo "$PUB_KEY" >> $HOME/.ssh/authorized_keys

	/etc/init.d/ssh_tunnel restart
}

bitbucket_key () {
	mkdir -p $HOME/.ssh
	chmod 700 $HOME/.ssh

	cp $files_dir/bitbucket $HOME/.ssh/bitbucket
	cp $files_dir/bitbucket.pub $HOME/.ssh/bitbucket.pub

	chmod 600 $HOME/.ssh/bitbucket
	chmod 600 $HOME/.ssh/bitbucket.pub

	cat << EOF > $HOME/.ssh/config
Host bitbucket.org
	IdentityFile ~/.ssh/bitbucket
EOF

}

aws_credentials () {
	mkdir -p $HOME/.aws
	cp $files_dir/aws_credentials $HOME/.aws/credentials
}

create_bashrc () {
	cp $files_dir/bashrc $HOME/.bashrc
}

read_set_hostname() {
	read -p "Enter new hostname: " hn
	set_hostname $hn
}

set_hostname () {
	hn=$1
	echo $hn > $HOME/hostname
}

read_enable_4g () {
	read -e -p "Write connection name: " name
	read -e -p "Write APN: " apn
	enable_4g $name $apn
}

enable_4g () {
	name=$1
	apn=$2

	DETECTED=
	PPP_PORT=$(echo /dev/serial/by-id/usb-Silicon_Labs_CP2105_Dual_USB_to_UART_Bridge_Controller_*-if01-port0)
	echo "$PPP_PORT"
	if [ -e "$PPP_PORT" ]; then
		echo "nRF91 shield detected"
		DETECTED=true
		enable_nrf91 $PPP_PORT
	fi

	SIM_PORT=$(echo /dev/serial/by-id/usb-SimTech__Incorporated_SimTech__Incorporated_*-if00-port0)
	if [ -e "$SIM_PORT" ]; then
		echo "SIM7600 shield detected"
		DETECTED=true
		enable_sim7600 $name $apn
	fi


	if [ -z "$DETECTED" ]; then
		echo "No shield detected"
	fi

}

enable_nrf91 () {

	cat << EOF > $HOME/4g_config
# This file only applies to nRF91 Shield
run_4g=1
ppp_port=$1
EOF

	/etc/init.d/ppp stop
	sleep 2
	/etc/init.d/ppp start

}

enable_sim7600 () {
	name=$1
	apn=$2

	nmcli connection add type gsm ifname '*' con-name "$name" apn "$apn" connection.autoconnect yes
}

strindex () {
	x="${1%%"$2"*}"
	[[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

upload_fw () {
	fw_dir=$(mktemp -d)
	unzip /opt/gw-firmware/gateway_heimdall_boardv2* -d $fw_dir

	openocd -f heimdall.cfg \
		-c "erase" \
		-c "program $fw_dir/sd.hex verify" \
		-c "program $fw_dir/app.hex verify" \
		-c "rg exit"

	rm -rf $fw_dir
}

enable_wifi () {
	nmcli device wifi connect $1 password $2
}

enable_wifi_interactive () {
	create_nm_folder

	NMOUT=$(nmcli -f "SSID, SIGNAL, SECURITY" -c yes  dev wifi list)
	HEADS=$(echo "$NMOUT"  | head -n 1)
	SSIDS=$(echo "$NMOUT"  | tail -n +2)

	SSID_POS=$(strindex "$HEADS" "SIGNAL")

	args=()
	while IFS= read -r line ; do args+=("$line"); done <<< "$SSIDS"

	args+=("other")

	menu_from_array "${args[@]}"

	if [ "$item" == "other" ]; then
		read -e -p "Write SSID: " selected
		nmcli --ask device wifi connect "$selected"
		return
	fi
	
	selected=$(echo "$item" | sed -e 's/\x1b\[[0-9;]*m//g' | head -c $SSID_POS | sed 's/^[ \t]*//;s/[ \t]*$//')

	if [ "$selected" == "--" ]; then
		echo "Can't connect to a network without SSID"
		return
	fi

	nmcli --ask device wifi connect "$selected"
}

menu_from_array () {
	COLUMNS=1
	select item; do
		if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ]; then
			break;
		else
			echo "Wrong selection: Select any number from 1-$#"
		fi
	done
}

create_nm_folder () {
	mkdir -p /home/root/NetworkManager/connections
}

print_usage() {
	echo "Usage: $0 -d files_dir [[--tunnel PORT] [--keys] [--aws] [--bashrc] [--hostname HOSTNAME] [--lte NAME APN] [--fw] [--wifi SSID PASSWORD]] | [--auto]"
}

auto_configure() {
	[[ -f "$HOME/.auto" ]] && exit 0

	echo "Installing bitbucket ssh key"
	bitbucket_key
	echo "Installing aws credentials"
	aws_credentials
	echo "Installing bashrc"
	create_bashrc
	echo "Uploading nRF gw-firmware"
	[[ $EUID -eq 0 ]] && upload_fw

	echo "Creating NM folder"
	[[ $EUID -eq 0 ]] && create_nm_folder

	echo "Touching .auto"
	touch $HOME/.auto
}

ttsetup_interactive() {
	[[ $EUID -eq 0 ]] && yes_or_no "Install ssh tunnel?" && read_config_ssh
	yes_or_no "Install bitbucket ssh key?" && bitbucket_key
	yes_or_no "Install aws credentials?" && aws_credentials
	yes_or_no "Install bashrc?" && create_bashrc
	[[ $EUID -eq 0 ]] && yes_or_no "Current hostname is \"$(hostname)\". Change?" && read_set_hostname
	[[ $EUID -eq 0 ]] && yes_or_no "Enable 4G internet" && read_enable_4g
	[[ $EUID -eq 0 ]] && yes_or_no "Upload nRF gw-firmware" && upload_fw
	[[ $EUID -eq 0 ]] && yes_or_no "Configure WiFi network?" && enable_wifi_interactive
	yes_or_no "Restart to apply changes?" && reboot
}

files_dir=
port=
new_hostname=
name=
apn=
ssid=
password=
auto=
usage=
do_tunnel=
do_keys=
do_aws=
do_bashrc=
do_hostname=
do_4g=
do_fw=
do_wifi=
while [[ $# -gt 0 ]]; do
	case $1 in
	-d)
		shift
		files_dir=$1
		;;
	--tunnel)
		shift
		if [ -n "$1" ]; then
			do_tunnel=true
			port=$1
		else
			usage=true
		fi
		;;
	--keys)
		do_keys=true
		;;
	--aws)
		do_aws=true
		;;
	--bashrc)
		do_bashrc=true
		;;
	--hostname)
		shift
		if [ -n "$1" ]; then
			do_hostname=true
			new_hostname=$1
		else
			usage=true
		fi
		;;
	--lte)
		shift
		if [ -n "$1" ] && [ -n "$2" ]; then
			do_4g=true
			name=$1
			apn=$2
			shift
		else
			usage=true
		fi
		;;
	--fw)
		do_fw=true
		;;
	--wifi)
		shift
		if [ -n "$1" ] && [ -n "$2" ]; then
			do_wifi=true
			ssid=$1
			password=$2
			shift
		else
			usage=true
		fi
		;;
	--auto)
		auto=true
		;;
	*)
		usage=true
		;;
	esac
	shift
done

echo "Running setup script as $(whoami)" 

if [ -z $files_dir ] || [ ! -d $files_dir ]; then
	usage=true
fi

if [[ $auto && ( $do_tunnel || $do_keys || $do_aws || $do_bashrc || $do_hostname || $do_4g || $do_fw || $do_wifi ) ]]; then
	usage=true
fi

if [ -n "$usage" ]; then
	print_usage
	exit 1
fi

if [ -n "$auto" ]; then
	auto_configure
	exit 0
fi

if [[ ! $do_tunnel && ! $do_keys && ! $do_aws && ! $do_bashrc && ! $do_hostname && ! $do_4g && ! $do_fw && ! $do_wifi ]]; then
	ttsetup_interactive
	exit 0
fi

if [ $do_tunnel ]; then
	config_ssh $port
fi

if [ $do_keys ]; then
	bitbucket_key
fi

if [ $do_aws ]; then
	aws_credentials
fi

if [ $do_bashrc ]; then
	create_bashrc
fi

if [ $do_hostname ]; then
	set_hostname $new_hostname
fi

if [ $do_4g ]; then
	enable_4g $name $apn
fi

if [ $do_fw ]; then
	upload_fw
fi

if [ $do_wifi ]; then
	enable_wifi $ssid $password
fi
