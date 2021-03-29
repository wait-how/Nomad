#!/bin/bash
# flash code onto a pair of EEPROMs, in order to write code to the nomad board using human intervention

if [ $# -lt 1 ];
then
	echo "$0 <path to arduino> <name of executable>"
	exit 0
fi

dest=$1
name=${2:-"test"}

cd ~/code/main/68k
make $name > /dev/null

if [ $? -eq 0 ];
then
	echo "Build succeeded."
else
	echo "Build failed."
	exit 1
fi

#if [ ! -e $dest ];
#then
#	echo "$dest does not exist!"
#	exit 2
#fi

./split $name.bin > /dev/null

echo "Writing program $name to EEPROM..."
echo "Connect LSB side of programmer and enter any key to continue."
read dummy
./eeprom_config --device=$dest --action=write --binary=$name.bin.lsb
echo "Connect MSB side of programmer and enter any key to continue."
read dummy
./eeprom_config --device=$dest --action=write --binary=$name.bin.msb
echo "upload completed."

