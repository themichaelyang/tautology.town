---
layout: post
title: "Learning about: IP addresses"
---

What makes a destination IP address authoritative? 

I know it's trivial to spoof a sender's IP address, but that you wouldn't receive a response because it would be routed
back to the spoofed address. This had me wondering:

- What prevents a destination IP address from being spoofed?
- How do we know an IP address we connect to is legitimate?

## The short answer

"Spoofing a destination IP address" is possible, and is known as *IP hijacking*. 

One way this can happen is if a malicious or misconfigured Autonomous System advertises incorrect BGP routes, known as [BGP hijacking](https://www.cloudflare.com/learning/security/glossary/what-is-bgp/#learning-content-h2).

## An explanation

The **Internet** is a network that connects other networks. An "inter-network" network, if you will. The largest network "unit" that the Internet interconnects is an **[Autonomous System (AS)](https://www.cloudflare.com/learning/network-layer/what-is-an-autonomous-system/)**.

Each AS has IP address ranges it controls, registered with a **[Regional Internet Registry (RIR)](https://en.wikipedia.org/wiki/Regional_Internet_registry)**. Each Autonomous System is also registered under a unique **Autonomous System Number (ASN)**.

Autonomous Systems connect with other Autonomous Systems and share routing information using the **[Border Gateway Protocol (BGP)](https://www.cloudflare.com/learning/security/glossary/what-is-bgp/)**.

BGP messages say something like: "[This is the next IP](https://datatracker.ietf.org/doc/html/rfc4271#section-5.1.3) to follow to [reach IPs with this prefix](https://datatracker.ietf.org/doc/html/rfc4271#autoid-11:~:text=Network%20Layer%20Reachability%20Information%3A), via [this path of ASNs](https://datatracker.ietf.org/doc/html/rfc4271#section-5.1.2)". This information is propagated transitively through Autonomous Systems and processed by each router to build their own [routing tables](https://en.wikipedia.org/wiki/Routing_table). The routing table says "to reach the IPs in this range, the next IP in the path is this".

### Routing packets

To [route a packet](https://en.wikipedia.org/wiki/IP_routing#Routing_algorithm) to a destination:

1. When a packet arrives at a router, the router looks up its routing table for a prefix matching the destination IP address.
2. It fowards the packet to the "next hop" IP address for that prefix. I think the next hop IP address is usually the local IP interface to a directly connected router.
4. The process repeats, until the destination is reached.

Your computer even has a routing table! Here's the one on my Mac (`routel` on Linux prints this nicer):

```bash
$ ip route
default via 192.168.0.1 dev en0
127.0.0.0/8 via 127.0.0.1 dev lo0
127.0.0.1/32 via 127.0.0.1 dev lo0
169.254.0.0/16 dev en0 scope link
192.168.0.0/24 dev en0 scope link
192.168.0.1/32 dev en0 scope link
192.168.0.197/32 dev en0 scope link
224.0.0.0/4 dev en0 scope link
255.255.255.255/32 dev en0 scope link
```

The first line is saying the default route to send traffic through is via 192.168.0.1 and device en0, if no other prefix is matched. `en0` is the network interface, and apparently refers to network card. If I run `arp -a | grep "(192.168.0.1)"`, I think it prints the MAC address of my wifi router. So, this is saying that the first hop goes through network card to my router.

On my home network, the ISP also assigns me a public IP address. The process works the same in reverse when receiving a response, until a packet reaches my router via my public IP and my router forwards the packet to my computer's local IP address via [NAT](https://en.wikipedia.org/wiki/Network_address_translation).

### Trust

A few things to notice:
- Any AS can announce with BGP that it knows a path to an IP address
- Any router along the routing path can fake a response to the packet


### Tracing routes

We can use `traceroute` to look at the path that a packet can take. 

Because no single router knows the full path of a request, [`traceroute` works by repeatedly making the request and incrementing the max hops from 1](https://en.wikipedia.org/wiki/Traceroute) then using the source IP of the returned error message and hop limit to infer the path of a request. (Interestingly, `traceroute` to this blog does not work, possibly because the Github Pages CDN does not reply)

Here's a `traceroute` from a DigitalOcean droplet to "example.com" (`-q 1` so only 1 IP is sampled per hop count):

```bash
$ traceroute -q 1 example.com
traceroute to example.com (23.192.228.84), 30 hops max, 60 byte packets
 1  138.68.34.248 (138.68.34.248)  1.054 ms
 2  143.244.192.80 (143.244.192.80)  1.841 ms
 3  143.244.227.102 (143.244.227.102)  1.654 ms
 4  143.244.225.47 (143.244.225.47)  1.618 ms
 5  *
 6  192.168.224.135 (192.168.224.135)  1.676 ms
 7  192.168.226.131 (192.168.226.131)  1.446 ms
 8  a23-192-228-84.deploy.static.akamaitechnologies.com (23.192.228.84)  1.542 ms
```

