#!/usr/bin/env python3
import argparse
import sys

if __name__ == "__main__":
	""" uploads code to the 68k board, which may or may not go into the EEPROMs.  Self-updating is not currently supported.
	
	This depends heavily on the construction of the bootloader, so this is a work in progress until the bootloader for the device itself is done.
	
	"""
	parser = argparse.ArgumentParser(description='Python script to upload code to a 68k board with a UART attached.')
	parser.add_argument('--version', action='version', version='Code upload tool v0.1')
	parser.add_argument('-d', '--device', type=str, help='UART device path')
	parser.add_argument('-b', '--binary', type=str, help='binary path')
	parser.add_argument('-s', '--speed', type=int, default=115200, help='baud rate to communicate at, defaulting to 115200')
	parser.add_argument('-i', '--size', type=int, default=0x1FFFF, help='size of flash memory, script will stop if binary is bigger than this')
	# TODO: find a good way to specify a list of options for the config byte without a bunch of options

	args = parser.parse_args()
	
	try:
		import serial
	except ModuleNotFoundError:
		print("pyserial module not found!")
		print("try installing pip, and then running 'python -m pip install pyserial'.")
		sys.exit(1)
	
	if args.device == None:
		print("cannot open device file!")
		sys.exit(2)
	
	print("Opening serial port with 8N1 " + str(args.speed) + " baud settings...")
	serport = serial.Serial(args.device, args.speed, timeout=5)

	try: # open binary to write
		with open(args.binary, "rb") as binfile:
			bindata = binfile.read()
	except IOError:
		print("binary cannot be opened!")
		sys.exit(3)

	config_byte = 0
	# NOTE: configuration bits here are not supported in the bootloader yet, but we still need to write a byte

	bin_length = len(bindata)

	if bin_length % 2 == 1: # word align if not word-aligned already
		bin_length += 1
	
	if (bin_length > args.size):
		print("binary size is greater than target will allow!")
		sys.exit(5)

	print("writing " + str(bin_length) + " bytes to " + args.load, end='')
	
	serport.write(config_byte)

	# write the length of the incoming binary, one byte at a time
	# doing this manually since bootloader expects 4 bytes regardless of value
	
	for i in range(4, 0):
		if bin_length == 0:
			serport.write(0)
		else:
			serport.write((bin_length >> (8 * i)) & 0xff)
			bin_length = bin_length >> 8
	
	serport.write(bindata)
	
	# bootloader echoes back the first word of RAM and the config byte to ack the binary transmission, check them for validity
	ram_word = serport.read(2)
	if ram_word != bindata[0:2]:
		print("first word of RAM does not match!")
		sys.exit(1)

	config_byte_read = serport.read(1)
	if config_byte_read != config_byte:
		print("config bytes do not match!")
		sys.exit(1)

	print("done.")

