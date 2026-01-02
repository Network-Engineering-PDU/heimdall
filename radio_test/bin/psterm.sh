#!/bin/bash

#set -x

export PATH="$PATH:/home/root/bin"

function run_wl_shell {

	echo "Starting Sterling-LWB wl shell"
	echo "Press Ctrl+C to exit"

	MY_PROMPT="wl>\$ "

	history -c

	while :
	do
		echo -n "$MY_PROMPT"
		read -e line

		if [ -z  "$line" ]; then
			echo
			continue
		fi

		history -s "$line"

		if echo "$line" | grep "^\s*wl\s\+" 2>&1 > /dev/null; then
			params=$(echo "$line" | sed "s/^\s*wl\s\+//")
			#echo "Executing: \"wl $params\""
			wl $params
		else
			echo "Write \"wl -h\" for help"
		fi
	done

	echo -e "\n---- exit ----"
	exit 0

}

function run_uart_shell {

	echo "Starting Miniew radio test shell"
	echo "Press Ctrl+C to exit"
	miniterm.py /dev/ttymxc6 115200 --raw --exit-char 3 -q
	echo -e "\n---- exit ----"
	exit 0
}

echo "Select test option:"


declare -a options
options+=( "Miniew MS88SF2 BLE Mesh" )
options+=( "Sterling-LWB WiFi/BLE" )

select opt in "${options[@]}"; do
	case ${opt} in
	${options[0]})
		run_uart_shell ;;
	${options[1]})
		run_wl_shell ;;
	(*) echo "Invalid option, press only 1 or 2" ;;
	esac
done

exit 0
