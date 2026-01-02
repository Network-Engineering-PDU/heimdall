import serial
import struct
import time
import sys

class Opcode:
    ECHO = 0x02
    APP = 0x20

class AppOpcode:
    SET_LED = 10

class Response:
    EVENT = 0x81
    ECHO = 0x82

class Event:
    DEV_RESET = 0x02
 
def serial_local(s, opcode, data=None):
    data = parse_data(data)
    packet = bytearray([len(data)+1, opcode])
    packet += data
    s.write(packet)

def send_led(s,r,g,b):
    packet = struct.pack("<BBBB", AppOpcode.SET_LED, r, g, b)
    serial_local(s, Opcode.APP, packet)



def parse_data(data):
    if isinstance(data, (bytes, bytearray)):
        return data
    if data is None:
        return bytes()
    if isinstance(data, str):
        return data.encode()
    if isinstance(data, int):
        return bytes.from_int(data, "little")
    raise ValueError("Invalid data type " + type(data))


def reader(s):
    packet = bytearray()
    packet += s.read(1)
    if len(packet) != 1:
        return None
    packet += s.read(packet[0])
    print("RX:", packet.hex(), packet)

    return packet[1:]

ECHO_STR = "test"

def echo(s):
    serial_local(s, Opcode.ECHO, ECHO_STR)
    packet = reader(s)

    if packet == None:
        print("RX timeout")
        return False

    if len(packet) != 1 + len(ECHO_STR):
        print("Wrong length")
        return False

    if packet[0] != Response.ECHO:
        print("Wrong rx opcode")
        return False

    if packet[1:].decode() != ECHO_STR:
        print("Wrong rx string")
        return False

    return True

def flush(s):
    s.flush()
    while True:
        rx = reader(s)
        if rx == None:
            return


if __name__ == "__main__":
    if len(sys.argv) not in [3, 4]:
        print("Wrong number of arguments")
        exit(1)

    s = serial.Serial(sys.argv[1], 115200, rtscts=True, timeout=0.5)
    flush(s)

    if sys.argv[2] == "echo":
        if len(sys.argv) != 3:
            print("Wrong number of arguments")
            exit(1)

        if echo(s):
            exit(0)
        else:
            exit(1)

    elif sys.argv[2] == "led":
        if len(sys.argv) != 4:
            print("Wrong number of arguments")
            exit(1)

        if len(sys.argv[3]) != 6:
            print("Color must be on hex form: RRGGBB")

        r = int(sys.argv[3][0:2], base=16)
        g = int(sys.argv[3][2:4], base=16)
        b = int(sys.argv[3][4:6], base=16)

        send_led(s, r, g, b)
        exit(0)

    else:
        print("Wrong argument")
        exit(1)
