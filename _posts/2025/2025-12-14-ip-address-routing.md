---
layout: post
title: "Learning about IP address routing"
---

One question I had for a long time: What makes a destination IP address authoritative? 

I know you can [spoof sending a message as a different IP address](https://www.cloudflare.com/learning/ddos/glossary/ip-spoofing/), but even if your ISP didn't prevent you, you wouldn't receive a response because it would be routed to the actual location of the address you spoofed. This had me wondering:

- What prevents a destination IP address from being spoofed?
- How do we know an IP address we connect to is legitimate?

## The short answer

The destination of an IP address is determined through decentralized routing, a protocol called BGP, loose coordination between large computer networks, regional registries for IP address ranges, and lots of trust!

"Spoofing a destination IP address" is possible, and is known as *IP hijacking*. One way this can happen is if a malicious or misconfigured actor advertises incorrect routing to the rest of the network, known as [BGP hijacking](https://www.cloudflare.com/learning/security/glossary/what-is-bgp/#learning-content-h2).

----

## A long explanation

The **Internet** is a network that connects other networks. An "inter-network" network, if you will. An **[Autonomous System (AS)](https://www.cloudflare.com/learning/network-layer/what-is-an-autonomous-system/)** is the largest network "unit" that the Internet interconnects.

- Each AS has IP address ranges it controls, registered with a **[Regional Internet Registry (RIR)](https://en.wikipedia.org/wiki/Regional_Internet_registry)**. An AS knows how to reach any IP address in its ranges.
- Each AS is identified by an **Autonomous System Number (ASN)** assigned by their RIR.
- Autonomous Systems are connected to other Autonomous Systems and share reachability using the **[Border Gateway Protocol (BGP)](https://www.cloudflare.com/learning/security/glossary/what-is-bgp/)**.

BGP messages say something like: "[This is the next IP](https://datatracker.ietf.org/doc/html/rfc4271#section-5.1.3) to follow to [reach IPs with this prefix](https://datatracker.ietf.org/doc/html/rfc4271#autoid-11:~:text=Network%20Layer%20Reachability%20Information%3A), via [this path of ASNs](https://datatracker.ietf.org/doc/html/rfc4271#section-5.1.2)". This information is propagated transitively through Autonomous Systems and processed by each router to build their own [routing tables](https://en.wikipedia.org/wiki/Routing_table). 

A routing table says "to reach the IPs in this range, the next IP in the path is this".

### Routing packets

When you send a packet, it's [passed from router to router](https://en.wikipedia.org/wiki/IP_routing#Routing_algorithm):

1. When a packet arrives at a router, the router looks up its routing table for a prefix matching the destination IP address.
2. The router forwards the packet to the "next hop" IP address for that prefix. I think the next hop IP address is usually the local IP interface to a connected router.
4. The process repeats, until the destination is reached.

On my home network, the ISP assigns me a public IP address. The process works the same in reverse when receiving a response, until a packet reaches my router via my public IP and my router forwards the packet to my computer somehow.

### Trust and coordination

By design, the Internet is decentralized. The hop-by-hop nature of routing means an AS need only talk to its own neighbors in order to reach the entire connected set. 

A few things to notice:

1. Autonomous Systems have full discretion with what they announce with BGP and could [lie about the ASN path](https://blog.apnic.net/2021/05/24/a-tool-to-detect-bgp-lies/).
2. Routing information is propagated throughout the network.
3. Any router along the routing path can [man-in-the-middle (MITM)](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) a packet.
4. Routers have discretion in deciding how to route a packet.

Any rogue router along the path could respond or tamper with a packet. You place a lot of trust into your ISP! 

The rogue router could have a fake shorter or more specific route advertised with BGP, leading to traffic being consistently routed to it. This is exactly what BGP hijacking is. On top of hacks, this happens at lot by accident (e.g. [route leaks](https://blog.apnic.net/2025/05/06/analysis-of-a-route-leak/)), causing some famous outages. 

It's a big enough problem that Cloudflare has a dedicated microsite: [isbgpsafeyet.com](https://isbgpsafeyet.com/). 

> Is BGP safe yet? No.

There are many [strategies to improve BGP security](https://networkphil.com/2024/02/20/best-practices-for-enhancing-bgp-security/), but the simplest is to cross check against another source. RIRs know what IP ranges go to which ASNs, so an AS announcing a route origin can be cross checked against the RIR's signed records, known as **Resource Public Key Infrastructure (RPKI)**. There are also databases called **Internet Routing Registries (IRR)** that Autonomous Systems publish routes to that can be used to filter obviously invalid routes. In practice, a large AS will be selective with who they accept BGP messages from and have [different peering arrangements](https://www.cloudflare.com/learning/network-layer/what-is-peering/).

This isn't perfect: we still have the man-in-the-middle problem, and an AS could still lie while publishing a legitimate-looking route. 

This is why things like HTTPS are important --- although, you [still need to trust somebody](https://www.cs.cmu.edu/~rdriley/487/papers/Thompson_1984_ReflectionsonTrustingTrust.pdf), in this case the root cert.

---

## Addendum: a few things to try

### Routing tables

Your computer has a routing table. Here's the one on my laptop (`routel` on Linux prints this nicer):

```
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

The first line is saying the default route to send traffic through is via 192.168.0.1 and device en0, if no other prefix is matched. `en0` is the network interface, and apparently refers to my laptop's network card. If I run `arp -a | grep "(192.168.0.1)"`, I think it prints the MAC address of my wifi router. 

So, this is saying that the first hop goes through network card to my router.

### Tracing routes

We can use `traceroute` (or `mtr`) to look at the path that a packet can take.

Because no single router knows the full path of a request, `traceroute` works by [repeatedly sending packets with an incrementing hop limit](https://en.wikipedia.org/wiki/Traceroute) then using the source IP of the error message response and hop count to infer the path of a request. (Interestingly, `traceroute` to this blog does not work, possibly because the Github Pages CDN does not reply, although `mtr` works.)

Here's a `traceroute` from a DigitalOcean droplet to "example.com" (`-q 1` so only 1 IP is sampled per hop count):

```
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

I looked up the ASNs associated with each IP by looking it up on [bgp.tools](https://bgp.tools/). Surprisingly, most were not found by bgp.tools although most were at least found in RIR registries.
- `138.68.34.248`: [138.68.34.0/24](https://bgp.tools/prefix/138.68.34.0/24) originated by AS14061 (DigitalOcean).
- `143.244.192.80`: No prefix match, but allocated to [ARIN-DO-13](https://bgp.tools/rir-owner/ARIN-DO-13) (DigitalOcean).
- `143.244.227.102`: No prefix match, but allocated to [ARIN-DO-13](https://bgp.tools/rir-owner/ARIN-DO-13) (DigitalOcean).
- `143.244.225.47`: No prefix match, but allocated to [ARIN-DO-13](https://bgp.tools/rir-owner/ARIN-DO-13) (DigitalOcean).
- `192.168.224.135`: Not found anywhere, 192.168.0.0/16 is a private address space.
- `192.168.226.131`: Not found anywhere, 192.168.0.0/16 is a private address space.
- `23.192.228.84`: Overlapping Prefixes Detected, both under [AS20940](https://bgp.tools/prefix-selector?ip=23.192.228.84) (Akamai).

For the unannounced ASNs, I assume these are part of the private network of DigitalOcean as the request finds its way out of the VPS network. I assume the private address spaces are related to that, and that Akamai and DigitalOcean are connected somewhere in an [Internet Exchange Point (IXP)](https://en.wikipedia.org/wiki/Internet_exchange_point) with some internal infrastucture corresponding to the two private IP addresses.

To learn more, you might like [this post](https://jvns.ca/blog/2021/10/05/tools-to-look-at-bgp-routes/) from Julia Evans.