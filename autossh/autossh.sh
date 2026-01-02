#!/bin/bash

run_autossh=0

[ -e /home/root/ssh_config ] && . /home/root/ssh_config

if [ $run_autossh = 1 ]
then
	echo "Autossh start"
	running=1

	trap "running=0; ssh -S /var/run/autossh.socket -O exit $ssh_ip" SIGINT

	while true; do
		echo "try to connect..."
		ssh -i $ssh_key -N -M -S /var/run/autossh.socket -o ExitOnForwardFailure=yes -o ServerAliveInterval=240 -R $ssh_port:localhost:22 $ssh_user@$ssh_ip &
		wait $!

		if (( $running == 1 )); then
			echo "restarting in 5 seconds.."
		else
			echo "Stopping tunnel"
			break
		fi
		sleep 5
	done

fi
