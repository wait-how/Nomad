/*
  Another EEPROM programmer, implemented on the Arduino Mega.
  This is the hardware side, which receives commands from a python script running on the host and writes the bit pattern into EEPROM.
  This version targets the GLS29EE010 EEPROM chip, which is special because it implements JEDEC write protection on all pages.
  The code could be made to work with other EEPROMS, as the GLS29EE010 isn't super different than other common EEPROM chips.

  All pin connections below are on the rightmost connector on the board, to ease wiring concerns and allow for other things to be connected.
  (Arduino Mega layout)
  
  Timing variables are the same as in the GLS29EE010 datasheet.

  Pinout:
  53: !OE - PB0
  52: A10 - PB1
  51: A11 - PB2
  50: A9 - PB3
  49: A8 - PL0
  48: A13 - PL1
  47: A14 - PL2
  46: !WE - PL3
  45: A16 - PL4
  44: A15 - PL5
  43: A12 - PL6
  42: A6 - PL7
  41: A7 - PG0
  40: A4 - PG1
  39: A5 - PG2
  38: A2 - PD7
  37: A3 - PC0
  36: A0 - PC1
  35: A1 - PC2
  34: DQ0 - PC3
  33: DQ2 - PC4
  32: DQ1 - PC5
  31: DQ3 - PC6
  30: DQ5 - PC7
  29: DQ4 - PA7
  28: DQ7 - PA6
  27: !CE - PA5
  26: DQ6 - PA4
  25: -
  24: Status LED - n/a
  23: -
  22: -

  // 1 is output, 0 is input
  D0 = C3
  D1 = C5
  D2 = C4
  D3 = C6
  D4 = A7
  D5 = C7
  D6 = A4
  D7 = A6

  A0 = C1
  A1 = C2
  A2 = D7
  A3 = C0
  A4 = G1
  A5 = G2
  A6 = L7
  A7 = G0
  A8 = L0
  A9 = B3
  A10 = B1
  A11 = B2
  A12 = L6
  A13 = L1
  A14 = L2
  A15 = L5
  A16 = L4

  CE = A5
  WE = L3
  OE = B0
  
  Command syntax:

Format: <operation>: <arg>: <arg>: <arg>;
ER;  erase the chip, which in this case sets all memory locations to 0xFF
VE;  get version information about the interface code and the chip connected
RP: <decaddr>;  read a page out of memory, display as raw data
RPI: <decaddr>;  read a page out of memory, display as decimal and in a pretty format for debugging
WP: <decaddr>: <values>  write a page into memory, use raw data
RD: <decaddr>;  read a word out of memory
WR: <decaddr>: <value>  write a word into memory
  NOTE: neither RD and WR are actually implemented since the chip works on 128-byte pages and writing and reading words is wildly inefficient.
FL: <decaddr>: <len>: <value>;  fill memory with <value> from <decaddr> to <len> - NOT IMPLEMENTED
NP;  do nothing

*/

#include <stdint.h>
#include <string.h>
#include <stdlib.h>

const int AST = 24; // status LED pin

const char *version_string = "EEPROM Flasher v0.3";

enum input_directions {
  IN,
  OUT,
};

typedef struct {
  uint8_t manufacturer_id;
  uint8_t device_id;
} device_info_t;

// set the data direction of the data bus directly
void set_data_pin_mode(bool dir) {
  if (dir) { // out
    DDRC |= 0b11111000;
    DDRA |= 0b11010000;
  } else { // in
    DDRC &= 0b00000111;
    DDRA &= 0b00101111;
  }
}

// set the address bus to a specific value directly
void set_addr_bus(long addr) {
  bitWrite(PORTC, 0, (addr >> 3) & 1L);
  bitWrite(PORTC, 1, addr & 1L);
  bitWrite(PORTC, 2, (addr >> 1) & 1L);
  
  bitWrite(PORTD, 7, (addr >> 2) & 1L);

  bitWrite(PORTG, 0, (addr >> 7) & 1L);
  bitWrite(PORTG, 1, (addr >> 4) & 1L);
  bitWrite(PORTG, 2, (addr >> 5) & 1L);

  bitWrite(PORTL, 0, (addr >> 8) & 1L);
  bitWrite(PORTL, 1, (addr >> 13) & 1L);
  bitWrite(PORTL, 2, (addr >> 14) & 1L);
  bitWrite(PORTL, 4, (addr >> 16) & 1L);
  bitWrite(PORTL, 5, (addr >> 15) & 1L);
  bitWrite(PORTL, 6, (addr >> 12) & 1L);
  bitWrite(PORTL, 7, (addr >> 6) & 1L);

  bitWrite(PORTB, 1, (addr >> 10) & 1L);
  bitWrite(PORTB, 2, (addr >> 11) & 1L);
  bitWrite(PORTB, 3, (addr >> 9) & 1L);
}

// grab existing data off bus
// requires proper pin mode
uint8_t get_data_bus() {
  uint8_t data;

  bitWrite(data, 0, bitRead(PINC, 3));
  bitWrite(data, 1, bitRead(PINC, 5));
  bitWrite(data, 2, bitRead(PINC, 4));
  bitWrite(data, 3, bitRead(PINC, 6));
  bitWrite(data, 4, bitRead(PINA, 7));
  bitWrite(data, 5, bitRead(PINC, 7));
  bitWrite(data, 6, bitRead(PINA, 4));
  bitWrite(data, 7, bitRead(PINA, 6));
  
  return data;
}

// put a byte on the data bus
// requires proper pin mode
void set_data_bus(uint8_t data) {
  bitWrite(PORTC, 3, bitRead(data, 0));
  bitWrite(PORTC, 5, bitRead(data, 1));
  bitWrite(PORTC, 4, bitRead(data, 2));
  bitWrite(PORTC, 6, bitRead(data, 3));
  bitWrite(PORTA, 7, bitRead(data, 4));
  bitWrite(PORTC, 7, bitRead(data, 5));
  bitWrite(PORTA, 4, bitRead(data, 6));
  bitWrite(PORTA, 6, bitRead(data, 7));
}

// blocks until the pending write is complete
// should take ~Twc + Tblco
// minimal setup since this should only be called in a function that has recently written something
inline void check_write_complete() {
  set_data_pin_mode(IN);
  uint8_t temp1 = 0, temp2 = 0;
  
  do {
    bitClear(PORTB, 0); // OE
    bitClear(PORTA, 5); // CE
    bitWrite(temp1, 0, bitRead(PINA, 4)); // DQ6
    bitSet(PORTA, 5); // CE
    bitSet(PORTL, 3); // WE
    __asm__("nop\n\t");
    bitClear(PORTB, 0); // OE
    bitClear(PORTA, 5); // CE
    bitWrite(temp2, 0, bitRead(PINA, 4)); // DQ6
    bitSet(PORTA, 5); // CE
    bitSet(PORTL, 3); // WE
  } while (temp1 != temp2);
}

void eeprom_erase() {
  eeprom_write_cntl(0x5555, 0xAA); // EEPROM erase sequence in datasheet
  eeprom_write_cntl(0x2AAA, 0x55);
  eeprom_write_cntl(0x5555, 0x80);
  eeprom_write_cntl(0x5555, 0xAA);
  eeprom_write_cntl(0x2AAA, 0x55);
  eeprom_write_cntl(0x5555, 0x10);

  delay(21); // Tblco + Tsce
}

// returns struct containing device info
device_info_t eeprom_get_id() {
  device_info_t device;
  
  eeprom_write_cntl(0x5555, 0xAA);
  eeprom_write_cntl(0x2AAA, 0x55);
  eeprom_write_cntl(0x5555, 0x90);
  
  device.manufacturer_id = eeprom_read_cntl(0);
  
  __asm__("nop\n\t");
  
  device.device_id = eeprom_read_cntl(1);
  
  eeprom_write_cntl(0x5555, 0xAA);
  eeprom_write_cntl(0x2AAA, 0x55);
  eeprom_write_cntl(0x5555, 0xF0);
  
  return device;
}

// write a page (128 bytes) into EEPROM
// page has to start on a 128-byte page boundary
void eeprom_write_page(long page, uint8_t *page_buf) {
  eeprom_write_cntl(0x5555, 0xAA); // unlock?
  eeprom_write_cntl(0x2AAA, 0x55);
  eeprom_write_cntl(0x5555, 0xA0);
  
  bitClear(PORTL, 3); // WE
  bitSet(PORTB, 0); // OE
  set_data_pin_mode(OUT);
  set_data_bus(page_buf[0]);
  set_addr_bus(page);
  
  for (int i = 0; i < 128; i++) { // write all other bytes
    set_addr_bus(page + i);
    set_data_bus(page_buf[i]);
    bitClear(PORTA, 5); // CE
    __asm__("nop\n\t");
    bitSet(PORTA, 5); // CE
  }
  
  delayMicroseconds(200); // Tblco, have to wait for the byte load period to expire once the page load is done
  
  bitSet(PORTA, 5); // CE
  bitSet(PORTL, 3); // WE
  bitSet(PORTB, 0); // OE
  
  check_write_complete();
}

// read a page (128 bytes) out of EEPROM
// page doesn't have to be on a 128-byte page boundary
void eeprom_read_page(long page, uint8_t *page_buf) {
  bitSet(PORTL, 3); // WE
  bitClear(PORTB, 0); // OE
  set_data_pin_mode(IN);
  bitClear(PORTA, 5); // CE

  for (int i = 0; i < 128; i++) {
    set_addr_bus(page + i);
    page_buf[i] = get_data_bus();
  }

  bitSet(PORTA, 5); // CE
  bitSet(PORTL, 3); // WE
  bitSet(PORTB, 0); // OE
}

// write a single byte to a memory location
// both of the cntl functions are named as such because writing
// data a byte at a time is super slow and suitable only for configuration parameters.
void eeprom_write_cntl(long addr, uint8_t data) {
  set_addr_bus(addr);
  bitClear(PORTL, 3); // WE
  bitSet(PORTB, 0); // OE
  set_data_pin_mode(OUT);
  set_data_bus(data);
  bitClear(PORTA, 5); // CE

  __asm__("nop\n\t");

  bitSet(PORTA, 5); // CE
  bitSet(PORTL, 3); // WE
  bitSet(PORTB, 0); // OE
}

// read a byte from a memory location
uint8_t eeprom_read_cntl(long addr) {
  bitSet(PORTL, 3); // WE
  bitClear(PORTB, 0); // OE
  set_data_pin_mode(IN);
  set_addr_bus(addr);
  bitClear(PORTA, 5); // CE
  
  uint8_t data = get_data_bus();
  
  bitSet(PORTA, 5); // CE
  bitSet(PORTL, 3); // WE
  bitSet(PORTB, 0); // OE
  return data;
}

// get a string and null-terminate it
// since none of the Arduino serial functions are blocking
// tok_list is a list of delimiters
void cmd_get(char *buf, const char *tok_list) {
  int count = 0;
  for (;;) {
    if (Serial.available() > 0) {
      char temp = Serial.read();
      buf[count++] = temp;
      for (unsigned int i = 0; i < strlen(tok_list); i++) {
        if (tok_list[i] == temp) {
          buf[count - 1] = '\0';
          return;
        }
      }
    }
  }
}

// wait until data is available and then read it out to another buffer
void raw_val_get(uint8_t *buf) {
  const int read_val = 32;
  while (Serial.available() < read_val);

  for (int i = 0; i < read_val; i++) {
    buf[i] = Serial.read();
  }
}

char cmd_buf[64];
uint8_t page_buf[128];
char *word_ptr;

void setup() {
  // set pins to correct states using registers since digitalWrite isn't fast enough.
  bitSet(PORTA, 5); // CE
  bitSet(DDRA, 5);

  delay(5); // Tpu-write

  bitSet(DDRB, 0); // OE
  bitSet(PORTB, 0);

  bitSet(DDRL, 3); // WE
  bitSet(PORTL, 3);

  bitSet(DDRC, 0);
  bitSet(DDRC, 1);
  bitSet(DDRC, 2);
  
  bitSet(DDRD, 7);

  bitSet(DDRG, 0);
  bitSet(DDRG, 1);
  bitSet(DDRG, 2);

  bitSet(DDRL, 0);
  bitSet(DDRL, 1);
  bitSet(DDRL, 2);
  bitSet(DDRL, 4);
  bitSet(DDRL, 5);
  bitSet(DDRL, 6);
  bitSet(DDRL, 7);

  bitSet(DDRB, 1);
  bitSet(DDRB, 2);
  bitSet(DDRB, 3);

  set_addr_bus(0L);
  set_data_pin_mode(IN);

  pinMode(AST, OUTPUT);
  digitalWrite(AST, LOW); // "Activity" indicator LED
  
  // using 250k baud for inceased upload speed
  // ideally, I would profile the Arduino program to see if enough time is being spent on data transfer from host to Arduino to justify such a high baudrate.
  // however, the Arduino IDE has no good profiling capabilities, and I don't want to spend the time on it.
  // if I wanted to, I could use the Arduino Serial Timestamp function as a performance counter.  No idea if that would work.
  Serial.begin(250000); // 8N1, 250k Baud, no line ending
  while (!Serial) {
    ; // prevents garbage on the serial line
  }
  Serial.println("EEPROM Programmer ready.");
}

void loop() {
  cmd_get(cmd_buf, ":;"); // get the first command

  digitalWrite(AST, HIGH); // doing something, turn on "activity" led
  if (!strcmp(cmd_buf, "RP")) {
    cmd_get(cmd_buf, ";");
    long page = strtol(cmd_buf, NULL, 10);
    eeprom_read_page(page, page_buf);
    for (int i = 0; i < 128; i++) {
      Serial.write(page_buf[i]); // send data in bin, not ascii
    }
    Serial.write('\n');
  } else if (!strcmp(cmd_buf, "RPI")) { // read page interactive, used as a debug function
    cmd_get(cmd_buf, ";");
    long page = strtol(cmd_buf, NULL, 10);
    eeprom_read_page(page * 128, page_buf); // indexed by page, not by byte

    Serial.print("Data at page ");
    Serial.print(page);
    Serial.print(" (addr 0x");
    Serial.print(page * 128, HEX);
    Serial.println("):");
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 16; j++) {
        Serial.print(page_buf[(i * 16) + j]);
        Serial.print(" ");
      }
      Serial.println("");
    }
    Serial.println("done.");
  } else if (!strcmp(cmd_buf, "WP")) {
    cmd_get(cmd_buf, ":");
    long page = strtol(cmd_buf, NULL, 10);
    
    // NOTE: this has to be split up into >= 2 writes on the host side as well, since the Arduino rx serial buffer is only 64 bytes long.
    // I decided to split it into 4 writes instead, and I don't think this hurts transfer speeds too much
    raw_val_get(page_buf);
    raw_val_get(page_buf+32);
    raw_val_get(page_buf+64);
    raw_val_get(page_buf+96);
    
    eeprom_write_page(page, page_buf); // write the page once received
    Serial.println("done.");
  } else if (!strcmp(cmd_buf, "VE")) { // get version info from chip and print it, usually used to test if everything is working ok
    device_info_t device_info = eeprom_get_id();
    Serial.println(version_string);
    Serial.print("Manufacturer ID: 0x");
    Serial.println(device_info.manufacturer_id, HEX);
    Serial.print("Device ID: 0x");
    Serial.println(device_info.device_id, HEX);
    Serial.println("done.");
  } else if (!strcmp(cmd_buf, "ER")) { // erase the chip
    eeprom_erase();
    Serial.println("done.");
  } else if (!strcmp(cmd_buf, "NP")) { // do nothing
    Serial.println("done.");
  } else {
    Serial.print("Unknown command ");
    Serial.println(cmd_buf);
  }
  digitalWrite(AST, LOW); // turn off "activity" led when done with the activity
}
