#!/bin/bash

#set -x

export PATH="$PATH:/home/root/bin"
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0)

success=1

function print_result () {

	if [ "$1" = "PASS" ]; then
		echo -e "${GREEN}$1${NC}"
	elif [ "$1" = "FAIL" ]; then
		echo -e "${RED}$1${NC}"
	else
		echo -e "$1"
	fi
}

function print_code () {
	if [ $1 -eq 0 ]; then
		print_result "PASS"
	else
		success=0
		print_result "FAIL"
	fi
}


#openocd -f heimdall.cfg -c "program app.hex verify reset exit"
#openocd -f heimdall.cfg -c "program app.hex preverify verify reset exit"
#openocd -f heimdall.cfg -c "verify app.hex reset exit"
#openocd -f heimdall.cfg -c "erase exit"
#openocd -f heimdall.cfg -c "init" -c "reset halt" -c "nrf5 mass_erase" -c "exit"
#openocd -f heimdall.cfg -c "init" -c "reset halt" -c "verify_image app.hex" -c "reset run" -c "exit"


echo -e "\nStart TycheTools Heimdall selftest"

echo -ne "\nYocto linux loaded successfully...."
print_result "PASS"


echo -ne "\nUnzip nRF firmware...."

fw_dir=$(mktemp -d)
unzip /opt/gw-firmware/gateway_heimdall_boardv2* -d $fw_dir >> $fw_dir/out 2>&1
print_code $?

echo -ne "\nVerify nRF firmware...."
needs_program=0
openocd -f heimdall.cfg -c "verify $fw_dir/sd.hex reset exit" >> $fw_dir/out 2>&1
if [ $? -ne 0 ]; then
	needs_program=1
fi
openocd -f heimdall.cfg -c "verify $fw_dir/app.hex reset exit" >> $fw_dir/out 2>&1
if [ $? -ne 0 ]; then
	needs_program=1
fi

if [ $needs_program -eq 1 ]; then
	openocd -f heimdall.cfg -c "init" -c "reset halt" -c "nrf5 mass_erase" -c "exit" >> $fw_dir/out 2>&1
	print_code $?
else
	print_code 0
fi

echo -ne "\nProgram nRF softdevice...."
openocd -f heimdall.cfg -c "program $fw_dir/sd.hex preverify verify exit" >> $fw_dir/out 2>&1
print_code $?

echo -ne "\nProgram nRF firmware...."
openocd -f heimdall.cfg -c "program $fw_dir/app.hex preverify verify reset exit" >> $fw_dir/out 2>&1
print_code $?


echo -ne "\nnRF ECHO test...."
sleep 4
python3 uart_control.py /dev/ttymxc6 echo >> $fw_dir/out 2>&1
print_code $?

echo -ne "\nVerify USB devices...."
print_result "SKIP"

echo -ne "\nSet LED status...."
if [ $success -eq 0 ]; then
	python3 uart_control.py /dev/ttymxc6 led FF0000 >> $fw_dir/out 2>&1
	print_code $?
else
	python3 uart_control.py /dev/ttymxc6 led 00FF00 >> $fw_dir/out 2>&1
	print_code $?
fi

echo -ne "\nSelftest result...."
if [ $success -eq 0 ]; then
	print_result "FAIL"

	echo -e "\n${RED}*** VERBOSE SELFTEST RESULT ***"
	cat $fw_dir/out
	echo -e "\n*** END OF SELFTEST RESULT ***${NC}"
else
	print_result "PASS"
fi

rm -rf $fw_dir

echo -e "\nRestarting selftest procedure in 10 seconds"
sleep  10
exit 0
