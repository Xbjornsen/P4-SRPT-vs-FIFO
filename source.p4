/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_VLAN = 0x8100;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<16> egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;


header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header vlan_t {
	bit<3>   prio;
    bit<1>   cfi;
	bit<12>  id;
	bit<16>  etherType;
}
header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    diffserv;
    bit<2>    ecn;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    vlan_t       vlan;
    ipv4_t       ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
	          TYPE_VLAN: parse_vlan;
            default: accept;
        }
    }
    // User-defined parser state for vlan
    state parse_vlan {
        packet.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }

}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop();
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    

    action ToQueue0(){
        // set port to x.0 
       
         
    }
    action ToQueue1(){
    // set port to x.1

    }
    action ToQueue2(){
    // set port to x.2
        

    }
    action ToQueue3(){
    // set port to x.3
    }
    action ToQueue4(){
    // set port to x.4

    }
    action ToQueue5(){
    // set port to x.5

    }
    action ToQueue6(){
    // set port to x.6

    }
    action ToQueue7(){
    // set port to x.7

    }

    table TOS1_Audio{
        key = {
            hdr.vlan.id: range;
        }
        actions = {
            ToQueue0;
            ToQueue1;
            ToQueue2;
            ToQueue3;
            ToQueue4;
            ToQueue5;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    table TOS2_Video{
        key = {
            hdr.vlan.id: range;
        }
        actions = {
            ToQueue0;
            ToQueue1;
            ToQueue2;
            ToQueue3;
            ToQueue4;
            ToQueue5;
            ToQueue6;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    table TOS3_Best_Effort{
        key = {
            hdr.vlan.id: range;
        }
        actions = {
            ToQueue0;
            ToQueue1;
            ToQueue2;
            ToQueue3;
            ToQueue4;
            ToQueue5;
            ToQueue6;
            ToQueue7;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }


    apply {
        if(hdr.ipv4.diffserv == 0x1)
            TOS1_Audio.apply();
        else if(hdr.ipv4.diffserv == 0x2)
            TOS2_Video.apply();
        else if(hdr.ipv4.diffserv == 0x3)
            TOS3_Best_Effort.apply();

        /*
        if (hdr.ipv4.isValid()) {
            ipv4_tos.apply();
        }
        */
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    apply { }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	            hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
	            hdr.ipv4.ecn,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan);
        packet.emit(hdr.ipv4);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
