#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import *
from scapy.utils import *


def get_if():
    ifs=get_if_list()
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface

def main():

    if len(sys.argv)<4:
        print 'pass 2 arguments: <destination> "<message>"'
        exit(1)

    addr = socket.gethostbyname(sys.argv[1])
    vlanid = int(sys.argv[2])
    iface = get_if()
    print "sending on interface %s to %s" % (iface, str(addr))
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
    pkt = pkt/Dot1Q(vlan=vlanid)
    pkt = pkt /IP(dst=addr, tos=1) / TCP(dport=1234, sport=random.randint(49152,65535)) / sys.argv[3]
    pkt.show()
    sendp(pkt, iface=iface, verbose=False)


if __name__ == '__main__':
    main()
