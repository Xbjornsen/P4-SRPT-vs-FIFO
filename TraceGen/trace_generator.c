/*
   The code generates the output_flow_file based on flow_cdf_file
   */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#include "cdf.h"

/* Basic flow settings */
int    host_num                  = 8; /* number of hosts */
int    flow_total_num            = 100000; /* total number of flows to generate */
int    flow_total_time           = 0; /* total time to generate requests (in seconds) */
//int    load                      = 100; /* average network load in Mbps per host */
int    incast                    = 0; /* all-to-one when set to 1 */
struct cdf_table *flow_size_dist = NULL; /* flow distribution table*/
char   flow_cdf_file[100]        = "cdf/dctcp.cdf"; /* flow size distribution file */
int    header_size               = 54; //54(TCP_hdr+IPv4_hdr+Ethernet) 86(MPTCP header,max_packet size 1428, TCP 1448) 
int    max_ether_size            = 1500;//1500

/** IP address configuration */

const char * const host_ip[] = {
	"18.0.1.1",
	"18.0.1.2",
	"18.0.1.3",
	"18.0.1.4",
	"20.0.2.1",
	"20.0.2.2",
	"20.0.2.3",
	"20.0.2.4"  
};

/*
const char * const host_ip[] = {
	"192.168.60.150",
	"192.168.60.223",
	"192.168.60.205",
	"192.168.60.139",
	"192.168.60.151",
	"192.168.60.123",
	"192.168.60.105",
	"192.168.60.206"  
};
*/

/* Port usage (port id used) */
int host_port_offset[] = {
	20000,
	20000,
	20000,
	20000,
	20000,
	20000,
	20000,
	20000
};

/* Get the next available port id of the host */
static int get_host_next_port(int host) 
{
	host_port_offset[host]++;
	return (host_port_offset[host]);
}

/* Generate poission process arrival interval */
double poission_gen_interval(double avg_rate)
{
	if (avg_rate > 0)
		return -logf(1.0 - (double)(rand() % RAND_MAX) / RAND_MAX) / avg_rate;
	else
		return 0;
}

int main(int argc, char **argv) 
{
	FILE   *output_flow_file = NULL;
	char   output_filename[100] = "trace_file/mdtcp-output.trace";
	int    flow_id = 0;
	int    flow_size = 0;
	double flow_start_time = 0.0; /* in second */
	int    max_payload_size = max_ether_size - header_size;
	double period_us;
	double load=100.0;/*load */	
	//int hosts_per_edge=2;
	int seed=754;


	if (argc > 3) {
		load=atof(argv[1]);
		flow_total_num=atoi(argv[2]);
		seed=atoi(argv[3]);
	
	} else if (argc < 2  && argc > 1)
	
	{
		load=atof(argv[1]);
	} else {
	     printf("Usage: ./trace_generator load(Mbps) totalflows seed(optional)\n");
	}


	flow_size_dist = (struct cdf_table*)malloc(sizeof(struct cdf_table));
	init_cdf(flow_size_dist);
	load_cdf(flow_size_dist, flow_cdf_file);
	// header_size=20B(IPv4)+20B(TCP+checksum)+14B(Ethernet)+4B(FCS)+12B(InterframeGap)+8B(Preamble)=78B

	/* Average request arrival interval (in microsecond) */
	double mean_flowsize = avg_cdf(flow_size_dist); 

	// max. sustained load for K=4 topology is 16*BW
	period_us = 8.0*(mean_flowsize+(mean_flowsize*header_size/max_payload_size))/(host_num*load); 


	/* Convert flow_total_time to flow_total_num */
	if (flow_total_num == 0 && flow_total_time > 0)
		flow_total_num = flow_total_time * 1000000 / period_us;

	printf("host_num        %d \n", host_num);
	printf("flow_total_num  %d \n", flow_total_num);
	printf("flow_total_time %d \n", flow_total_time);
	//printf("load            %d \n", load);

	//printf("avg_flowsize    %f \n", avg_cdf(flow_size_dist));
	//printf("period_us       %f \n", period_us);

	/* Set random seed */
	srand(seed); 

	/* Generate traffic flows */
	for (flow_id=0; flow_id<flow_total_num; flow_id++) {

		int src_host = rand() % host_num;
		int dst_host = rand() % host_num;

		/* Skip if the src_host and dst_host are the same */
//		while (src_host == dst_host || (src_host >3 && dst_host >3 ) || (src_host < 4 && dst_host < 4))
//			dst_host = rand() % host_num;
		while (src_host == dst_host || (src_host <= 3 && dst_host != src_host + 4 ) || (src_host >= 4 && src_host != dst_host + 4))
			dst_host = rand() % host_num;


		/* Assign flow size and start time */
		flow_start_time = flow_start_time + poission_gen_interval(1.0 / period_us) / 1000000;

		flow_size = gen_random_cdf(flow_size_dist);

		/* Incast: only accept dst_host = 0 */
		if (incast && dst_host != 0) {
			flow_id--;
			continue;
		}

		/* Write to output file */
		output_flow_file = fopen(output_filename, "a");
		fprintf(output_flow_file, "%d %s %s %d %d %d %.9f\n",
				flow_id,
				host_ip[src_host],
				host_ip[dst_host],
				get_host_next_port(src_host),
				get_host_next_port(dst_host),
				flow_size,
				flow_start_time);

		fclose(output_flow_file);

	}

	return 0;
}
