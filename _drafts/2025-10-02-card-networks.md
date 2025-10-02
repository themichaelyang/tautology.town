---
layout: post
title: "Card networks 101: What do Visa and Mastercard do?"
---

<script src="https://unpkg.com/mermaid@11.12.0/dist/mermaid.min.js"></script>

Most people can recognize the Visa and Mastercard brands. If you do, chances are you use one of their cards to transact every day. You may have some notion that most places (in the US) take both, but some places only take Visa (e.g. Costco), and vice versa.

So what do they do? [Here's Visa's attempt](https://www.youtube.com/watch?v=lnz2gRPDzrA) to answer that question.

A few things they don’t do[^dont-do]:

[^dont-do]: Nowadays they may have product offerings for some of these, or own subsidiaries that do some of these, but these are not core to the business of being a card network.

- They aren’t the company that provides the card. Nor are they a bank, though the card you have is probably issued by one (Chase, Capital One, BofA, etc). These are called **“card issuers”**.
- They don’t distribute point of sale methods or online checkouts, which are done by **payment processors**.
- They aren’t responsible for onboarding or underwriting stores and merchants. That is typically done by payment processors and banks, called **“merchant acquirers”**.
- They don’t manufacture or print cards.
- Nor do they manufacture the point of sale hardware.

Instead, Visa and Mastercard are **card networks**[^card-network-name], facilitating card transactions by connecting the cardholders and issuers to the merchants and acquirers.

[^card-network-name]: To be precise, they are the companies running the card networks. Colloquially, we call them the card networks. For example, VisaNet is technically the card network, Visa is the company/brand. Mastercard's is called Banknet. They both own and operate subsidiary networks, such as specialized debit and ATM networks, like Visa's Interlink and Plus, or Mastercard's Cirrus and Maestro, although technically VisaNet and Banknet can process debit (this is a story for another time).

This forms a [two-sided market](https://en.wikipedia.org/wiki/Two-sided_market) of all the participants in a transaction[^or-four]:

[^or-four]: Or four, depending on how you count.

<figure>
<pre class="mermaid">
---
config:
  theme: 'neutral'
  fontFamily: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  nodeSpacing: 20
  rankSpacing: 20
  flowchart: 
    subGraphTitleMargin: {bottom: 20}
---
%% For some reason arrows are still showing up in the Obsidian preview, but not in Mermaid online editor
flowchart LR
    subgraph Issuing[**Issuing**]
        direction TB
        CI[Card issuer] --- CH[Cardholder]
    end
    subgraph Acquiring[**Acquiring**]
        direction TB
        MA[Merchant acquirer] --- M[Merchant]
    end
    Issuing ---- CN[**Card network**]
    CN ---- Acquiring
</pre>
<figcaption>The key players in a card transaction.</figcaption>
</figure>

The card network's job is to enable card transactions, and also to spread the use of their card brands. 

This boils down to four key responsibilities:
1. Run the physical network infrastructure to route transactions.
2. Coordinate the banking network to settle transactions.
3. Set the incentives to encourage the use of the network.
4. Set and enforce rules of the network, including a mechanism for disputes.

For the rest of the discussion, we'll focus on Visa for simplicity, as it's what I'm most familiar with, although Mastercard operates in more or less the same ways.

# 1. Run the physical infrastructure

When we talk about networks in the context of telecommunications, we think of the Internet, a network of computers connected together by fiber and [deep sea cables](https://www.submarinecablemap.com/).

Indeed, card networks are no different, but predate the Internet (although now part of it): they maintain massive data centers and lease physical cables to connect issuers and acquirers electronically.

The card network role's in a transaction is *routing*. Similar to IP addresses,[^pan-exhaustion] card numbers, also known as Primary Account Numbers (PANs) are used to route requests from the merchant's checkout to the issuing bank, where the transaction gets checked then approved or declined. The first 6 to 8 digits of the PAN is called a Bank Identification Number, or BIN, and identifies the issuing bank.

<!-- TODO: support sidenotes/asides https://kau.sh/blog/jekyll-footnote-tufte-sidenote/ -->
[^pan-exhaustion]: Similar to IPv4, 16 digit PANs are rapidly exhausting due to the use of anonymized "token" PANs used by things like Apple/Google Pay and saved payment details.

Visa takes its data centers very seriously. They are highly secure, redundant, and fitted to survive all kinds of disasters. From [Inside Visa's Data Center (Network Computing, 2013)](https://www.networkcomputing.com/data-center-networking/inside-visa-s-data-center):

> "The company's flagship data center, dubbed Operations Center East, or OCE, is a 140,000-square-foot facility that Visa will only say is located "somewhere along the Eastern seaboard."

> "Not surprisingly, the facility, which is also designed to withstand earthquakes and gale-force winds up to 170 miles per hour, is locked down like a digital Fort Knox. The roads entering the complex have hydraulic bollards that can shoot up fast enough to stop a vehicle traveling up to 50 miles per hour dead in its tracks. (The road is too curvy to drive safely at higher speeds.) Visitors must pass through a security gate, be cleared by roving security teams, and then be subjected to a biometric scan before being admitted."

[Another article](https://web.archive.org/web/20120330102616/https://www.usatoday.com/tech/news/story/2012-03-25/visa-data-center/53774904/1/) claims Visa's OCE is guarded by a a moat.

That top secret location? In [Ashburn, Virginia](https://maps.app.goo.gl/tPEDWcTiY621sZz37), conveniently located by Trader Joe's and Topgolf.

<div>
{% include image.html url="/assets/2025/visa-oce-satellite.png" description='I think the "moat" is the pool of water on the top center-left.' %}
</div>

# 2. Run the banking network

# 3. Set incentives

# 4. Set rules and handle disputes

More cards → more merchants. More merchants → more cards.





In another article, they claim to have [a moat](https://web.archive.org/web/20120330102616/https://www.usatoday.com/tech/news/story/2012-03-25/visa-data-center/53774904/1/) protecting the data center.





> "Inside the pods, 376 servers, 277 switches, 85 routers and 42 firewalls--all connected by 3,000 miles of cable--hum around the clock, enabling transactions around the globe in near real-time and keeping Visa's business running."

> "Inside the pods, 376 servers, 277 switches, 85 routers and 42 firewalls--all connected by 3,000 miles of cable--hum around the clock, enabling transactions around the globe in near real-time and keeping Visa's business running."

[Top secret Visa data center banks on security, even has moat (USA Today, 2013)](https://web.archive.org/web/20120330102616/https://www.usatoday.com/tech/news/story/2012-03-25/visa-data-center/53774904/1/)

the crux of their operation is an electronic one, and