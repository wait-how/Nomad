#!/usr/bin/env python3
import sys # for exit
import os # for checking file existance

debug = False # turn on for printing of odd and even data streams

if __name__ == "__main__":
	""" split a binary into two files, one with even bytes and one with odd bytes. 
	
	Both files are called <original file>.lsb and <original file>.msb.
	
	"""
	print("binary file splitter, by Kyle Neil (1/19)")
	print("for use with 68k EEPROM programmer")
	if (len(sys.argv) < 2):
		print("split <source binary>")
		sys.exit(1)
	try:
		with open(sys.argv[1], "rb") as binsrc:
			bindata = binsrc.read()
	except IOError:
		print("binary cannot be opened!")
		sys.exit(1)
	else:
		print("found binary of size " + str(len(bindata)))
	
	lsbdata = []
	msbdata = []
	
	# line everything up on even memory addresses, since odd ones are never accessed
	# inverted A0, so ~UDS or ~LDS = 0
	for byte in range(0, len(bindata)):
		if byte % 2 == 0:
			if byte + 1 == len(bindata): # if the binary is of an odd size, pad it
				lsbdata.append(0)
			else:
				lsbdata.append(bindata[byte + 1]) # 68000 is a big endian machine
			msbdata.append(bindata[byte])
		else:
			msbdata.append(0x00) # 68000 accesses things on even bounderies I think
			lsbdata.append(0x00)
		if debug:
			print("word " + str(hex(byte)) + ": (LSB, MSB) (" + str(hex(lsbdata[-1])) + ", " + str(hex(msbdata[-1])) + ")")
	
	# write out split files
	with open(sys.argv[1] + ".lsb", "wb") as lsb_bin:
		lsb_bin.write(bytes(lsbdata))
	with open(sys.argv[1] + ".msb", "wb") as msb_bin:
		msb_bin.write(bytes(msbdata))
	
	print("done.")
