#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

typedef bit<9> egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>     etherType;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     totalLen;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     fragOffset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdrChecksum;
    ip4Addr_t   srcAddr;
    ip4Addr_t   dstAddr;
}

/* Architecture */
struct standard_metadata_t {
    bit<9>      ingress_port;
    bit<9>      egress_spec;
    bit<9>      egress_port;
    bit<32>     clone_spec;
    bit<32>     instance_type;
    bit<1>      drop;
    bit<16>     recirculate_port;
    bit<32>     packet_length;
}


/* HEADERS */ 

struct metadata {..}

struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;

}

/* ERROR */
error {
    Ipv4IncorrectVersion,
    IPv4OptionsNotSupported
}

/* PARSER */
parser MyParser(packet_in_packet,
        out headers hdr,
        inout metadata meta,
        inout standard_metadata_t) {
    state start {
        transition parse_ethernet;
    }
// User-defined parser state
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4
            default: accept;
        }
    }
}

/* CHECKSUM VERIFICAION */
control MyVerifyChecksum(in headers hdr,
                        inout metadata meta)
                        {
                            apply{}

}

/* INGRESS PROCESSING */
control MyIngress(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata ) {
    action drop(){
        mark_to_drop(standard_metadata);
        dropped = true;
    }
    action  ipv4_forward(macAddr_t, dstAddr, egressSpec_t, port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_lpm { 
        key = { 
            hdr.ipv4.dstAddr : lpm; 
            // standard match kinds:
            // exact, ternary, lpm
            } 
            // actions that can be invoked
            actions = {
                ipv4_forward; 
                drop; 
                NoAction; 
            } 
        // table properties 
        size = 1024;
        default_action = NoAction();
        }
        apply{
            //apply the table
            if (hdr.ipv4.isValid() ) {
                ipv4_lpm.apply();
            }
        }
}

/* EGRESS PROCESSING */
control MyEgress(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata){
    apply{

    }

}


/* CHECKSUM UPDATE */
control MyComputeChecksum(inout headers hdr,inout metadata meta) {
    apply{
        update_checksum(
            hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	        hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.fragOffset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr 
            },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
        }
}


/* DEPARSER */
control MyDeparser(inout headers hdr,
                inout metadata meta){
                    apply{
                        packet.emit(hdr.ethernet);
                        packet.emit(hdr.ipv4);
                    }

}

/* SWITCH */
V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser(),
)main; 

