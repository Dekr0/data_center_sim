- This is a program that simulates interactions and transactions happen 
within a simplified hypothetical data center network.
- There are two implementations of this program. The main difference is the 
type of data communication process between switches.
    - [FIFOs](https://github.com/Dekr0/data_center_sim/tree/fifo)
    - [Socket](https://github.com/Dekr0/data_center_sim/tree/socket)
- The background and specification is directly quoted with some amount rephrasing 
and trimming from the specification proposed by Prof. E. Elmallah. To see the 
original specification, please read [FIFO version](https://github.com/Dekr0/data_center_sim/blob/main/spec_fifo.pdf) and [Socket version
](https://github.com/Dekr0/data_center_sim/blob/main/spec_socket.pdf).

## Table of Contents

- [Background](#background)
- [Specification](#specification)
    - [Definition](#definition) 
    - [Network model](#model)
    - [Network operation](#operation)
    - [Forwarding table](#forwarding-table)
    - [Network topology and routing](#topology-routing)
- [Usage](#usage)

## Background <a name="background"></a>

- In recent years, many information technology companies have increased their 
reliance on data centers to provide the needed computational and communication 
services. A data center typically houses hundreds to tens of thousands hosts. 
Each host (also called a blade) includes CPU, memory, and disk storage. The 
blades are often stacked in racks with each rack holding 20 to 40 blades. At
the top of each rack, there is a packet switch, referred to as the Top of Rack 
(TOR) switch, that interconnects the blades in the rack with each other, and 
provides connectivity with other blades in the data center and the Internet.

## Specification <a name="specification"></a>

### Definition <a name="definition"></a>

- Let's consider a simplified hypothetical data center network where the TOR
switches are connected to a special device, called a *master switch*. 
- The architecture of the network uses a new network design paradigm, called 
*software-defined networking* where the TOR switches are assumed to be simple, 
fast, and inexpensive devices. 
- The master switch collects and processes information that enable it to 
give routing information to the TOR switches.

### Network Model <a name="model"></a>

- The program deals with a simplified network that includes the following devices.
    - A *master* switch device that has *k ≥ 1* bidirectional communication ports 
    to connect at most k TOR packet switches.
    - A set of *k* TOR packet switches. Each switch has 4 bidirectional ports 
    serving the following purposes.
        - Port 0 connects the switch to the master switch.
        - Ports 1 and 2: each port connects the switch to another peer packet 
        switch. A `null` value assigned to a port indicates that the port is not 
        connected to any switch.
        - Port 3 connects the switch to blades in the rack. Each blade has an 
        IP address `≤ MAXIP = 1000`. As the IP address associated with each 
        blade is unique, this port is associated with a unique range of IP 
        numbers, denoted `[IPlow,IPhigh]` (e.g., [100, 200]).

#### Network Operation <a name="operation"></a>

- During network operation, each packet switch receives data packets from either 
the blades in its rack (an input data file is used to specify such packets), or 
its neighboring switches connected to ports 1 and 2 (if any exists).
- In real life, each packet has a *header* part and a *data* part. 
- The header part stores information like the packet type, the source IP address 
(`srcIP`)) and the destination IP address (`destIP`).
- For simplicity, only the header part of each packet is being exchanged among 
the switches. The function of the network is to route each packet header to the 
specified destination.

#### Forwarding Tables <a name="forwarding-table"></a>

- Each packet switch is a simple device that stores a forwarding table, where
each row has the following fields:
```
| srcIP_lo | srcIP_hi | destIP_lo | destIP_hi | actionType | actionVal | pkCount |
```
- Each row defines a *pattern-plus-action rule*, where the pattern is composed of 
the first four fields, and the action is specified by the last three fields.
- An incoming packet header (with specified `srcIP` and `destIP` addresses) 
matches a rule if `srcIP ∈ [srcIP lo, srcIP hi]`, and `destIP ∈ [destIP lo, 
destIP hi]`. 
- If a match is found, the switch applies the corresponding action as follows:
    - If `actionType = forward` then the packet is forwarded to the port 
    number specified by `actionVal`, and the `pktCount` is incremented.
    - If `actionType = drop` then the packet is dropped from the switch, and 
    the `pktCount` is incremented.
- Initially (when a switch is rebooted), the forwarding table stores an initial 
rule. 
- Subsequently, when a packet header arrives to the switch, the switch tries 
to find a matching rule in its forwarding table. 
- If no match exists, the switch asks the master switch for a rule to add to 
the forwarding table and apply to the packet. 
- Assume that the forwarding table in each switch is large enough to hold rules 
for processing at most 100 arriving packet headers.

#### Network topology and routing <a name="topology-routing"></a>

- The master switch is responsible for issuing rules to packet switches so as 
to enable successful routing of packets.
- To simplify its operation, we assume that packet switches are connected to 
form a simple path topology. 
- In such a topology, port 1 of switch i is either assigned the null value, or 
connected to switch *i − 1* if *i > 0*.
- Similarly, port 2 of switch i is either assigned the null value, or connected 
to switch *i + 1* if *i < k − 1*.

## Usage <a name="usage"></a>

- The program can be invoked to simulate a master switch using `net_sim master 
[nSwitch]` where `nSwitch ≤ MAX_NSW(= 7)` is the number of switches in the network.
- The program can also be invoked to simulate a TOR packet switch using `net_sim 
pswi dataFile (null|pswj) (null|pswk) IPlow-IPhigh `.
- As an example, `net_sim psw4 file1.dat null psw5 100-110`. 
    - The program simulates packet switch number *i* by processing the commands 
    in the specified `dataFile`.
    - Port 1 (respectively, port 2) of packet switch *i* is connected to switch 
    *j*  (respectively, switch *k*). 
    - Either, or both, of these two switches may be `null`. 
    - Switch *i* handles traffic from hosts in the IP range `[IPlow-IPhigh]`.
- The master switch is able to receive `stdin` while processing incoming 
packets. Here are the following commands the master switch can process:
    - `info`. 
        - The program writes the stored information about the attached switches 
        that have sent a `HELLO` packet to the master switch. 
        - As well, for each transmitted or received packet type, the program 
        writes an aggregate count of packets of this type handled by the master 
        switch.
    - `exit`
- The packet / TOR switch is able to receive `stdin` while processing incoming 
packets. Here are the following commands the master switch can process:
    - `info`
        - The program writes all entries in the forwarding table, and for each 
        transmitted or received packet type, the program writes an aggregate 
        count of handled packets of this type.
    - `exit`
- Both types of switches are capable of receiving signal `USER1` and display 
the information specified by command `info`.

### Data File Format

- Each packet switch reads its arriving data packets from a common `dataFile`. 
The file has a number of lines formatted as follows:
    - A line can be empty
    - A line that starts with ’#’ is a comment line
    - A line of the form `pswi srcIP destIP` specifies that a packet with the 
    specified source and destination IP addresses has reached port 3 of `pswi`. 
    You may assume that the `srcIP` address lies within the range handled by the 
    switch. Only `pswi` processes this packet header; other switches ignore the 
    line.
    - A line of the form `pswi delay interval` where `interval` is an integer 
    in milliseconds, specifies that packet switch *i* should delay reading 
    (and processing) the remaining part of the data file for the specified 
    time interval. During this period, the switch should continue monitoring 
    and processing keyboard commands and packets received from the attached 
    devices. This features simulates delays in receiving packets from hosts 
    served by the switch.
- Note: The field separator used on each data line is composed of one, or more, 
space character(s).

### Packet Types

- Communication in the network uses messages stored in formatted packets. Each 
packet has a type, and carries a message (except `HELLO_ACK` packets). The program 
should support the following packet types.

#### `HELLO` and `HELLO_ACK`

- When a packet switch starts, it sends a `HELLO` packet to the master switch. 
- The carried message contains the switch number, the numbers of its neighboring
switches (if any), and the range of IP addresses served by the switch. 
- Upon receiving a `HELLO` packet, the master switch updates its stored information 
about the switch, and replies with a packet of type `HELLO_ACK` (no carried message).

#### `ASK` and `ADD`

- When processing an incoming packet header (the header may be read from
the data file, or forwarded to the packet switch by one of its neighbors), if 
a switch does not find a matching rule in its forwarding table, the switch 
sends an `ASK` packet to the master switch. 
- The master switch replies with a rule stored in a packet of type ADD. 
- The switch then stores and applies the received rule.

#### `REPLAY`

- A switch may forward a received packet header to a neighbor (as instructed by
a matching rule in the forwarding table). This information is passed to the 
neighbor in a `RELAY` packet.
