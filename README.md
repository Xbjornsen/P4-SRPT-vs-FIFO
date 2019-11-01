# P4-SRPT-vs-FIFO
Create a p4 network and manage the flows based on priority alogorthim SRPT - Shortest Remaining Processing Time. 

# Goal
The goal of this project was to see if the algorithm SRPT has a better performance for certain types of data flows compared to FIFO. 

# Progress
Currently the p4 code is stuck on sorting the traffic classes for egress spec. These classes help organise the queues that hold the flows to be sent out. 

# Testing 
To test this p4 code, a test bed needs to be set up with the p4 code to be flushed to all the switches in the topology. A traffic generator like the one in this repository needs to be implemented to create the correct data flows. 

# VLAN
Tagging between the switches is configured by VLAN bridges that use VLAN tagging. To complete this is the correct VLAN has to be tagged in to socket buffer and to let the socket buffer handle the tagging since the socket buffer holds the information for the tagging. 

# P4 programmers studio
The config file to set up a new project in p4 programmers studio is supplied and is called 'config.p4cfg' run this when creating the project to build the traffic classes and rules set for data flows for audio, video and besteffort. 

# p4 code
See attached 'source.p4' file, once the project is created in programmers studio copy this file in and build and compile it. 

# Topology 
See topology.json file to understand the topology of the testbed that we were using to test this project out on. 

