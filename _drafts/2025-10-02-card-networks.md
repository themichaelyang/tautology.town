---
layout: post
title: "(Draft) Card networks primer: What do Visa and Mastercard do?"
---

<script src="https://unpkg.com/mermaid@11.12.0/dist/mermaid.min.js"></script>

Most people can recognize the Visa and Mastercard brands. Chances are, you use one of their cards to transact every day. You may have some notion that most places (in the US) take both, but some places only take Visa (e.g. Costco), and vice versa.

So what do they do? [Here's Visa's attempt](https://www.youtube.com/watch?v=lnz2gRPDzrA) to answer that question.

A few things they don’t do[^dont-do]:

[^dont-do]: Nowadays they may have product offerings for some of these, or own subsidiaries that do some of these, but these are not core to the business of being a card network.

- They aren’t the company that provides the card. Nor are they a bank, though the card you have is probably issued by one (Chase, Capital One, BofA, etc). Those are called **“card issuers”**.
- They don’t distribute point of sale methods or online checkouts, which are done by **payment processors**.
- They aren’t responsible for onboarding or underwriting stores and merchants. That is typically done by payment processors and banks, called **“merchant acquirers”**.
- They don’t manufacture or print cards.
- Nor do they manufacture the point of sale hardware.

Instead, Visa and Mastercard are **card networks**[^card-network-name], facilitating card transactions by connecting the cardholders and issuers to the merchants and acquirers.

[^card-network-name]: To be precise, we use "card networks" to colloqially refer to the companies operating their own card payment networks / schemes. For example, *VisaNet* is technically the network, Visa is the company/brand. Mastercard's network is called *Banknet*. Both companies also own and operate specialized subsidiary networks for things like debit cards and ATMs, like Visa's Interlink and Plus, or Mastercard's Cirrus and Maestro, although technically VisaNet and Banknet can process debit (this is a story for another time). There are further terms to distinguish the telecommunications network with the bank network, and even subsets of each. Visa even thinks of itself as a ["network of networks"](https://annualreport.visa.com/business-overview/default.aspx#:~:text=Our%20network%20of%20networks%20strategy,transactions%2C%20no%20matter%20the%20network.). Turtles all the way down.

This forms a [two-sided market](https://en.wikipedia.org/wiki/Two-sided_market) of all the participants in a transaction[^or-four]:

[^or-four]: Or [four](https://www.marqeta.com/uk/demystifying-cards-guide/card-payments-ecosystem), depending on how you count.

<figure>
<pre class="mermaid wide" id="key-players">
---
config:
  theme: 'neutral'
  fontFamily: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  nodeSpacing: 20
  rankSpacing: 25
  flowchart: 
    subGraphTitleMargin: {bottom: 20}
    useMaxWidth: true
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
<!-- For some horrible reason, Mermaid.js is fixing the max-width even if useMaxWidth is true -->
<script>
window.addEventListener('load', () => {
  document.querySelectorAll(".mermaid svg").forEach(el => el.style = "")
})
</script>
<figcaption>The key players in a card transaction.</figcaption>
</figure>

The card network's job is to enable card transactions, and also to spread the use of their card brands. 

This boils down to four key responsibilities:
1. Run the telecommunications network to route transaction messages.
2. Coordinate the banking network to route money and settle transactions.
3. Set the incentives to encourage the use of the network.
4. Set and enforce rules of the network, including a mechanism for disputes.

For the rest of the discussion, we'll focus on Visa, as it's what I'm most familiar with, although the role of Mastercard is analogous.

# 1. Run the telecommunications network

When we talk about networks, we think of the Internet, computers connected together by fiber and [deep sea cables](https://www.submarinecablemap.com/).

Card networks are not so different. They maintain data centers and lease fiber optics cables that connect issuers and acquirers electronically.

During a 

When a card is used, the card network is responsible for routing transaction request messages, known as **authorizations**. Similar to IP addresses,[^pan-exhaustion] card numbers, also known as Primary Account Numbers (PANs) are used to route requests from the merchant's checkout to the issuer, where the authorization is approved or declined. The first 6 to 8 digits of the PAN is called a Bank Identification Number, or BIN, which identifies the issuing bank.

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

# 2. Coordinate the banking network

After a transaction is approved, money on both ends must move to fulfill the transaction, known as **settlement**. 

Visa's second job as a router is to *route money* for settlement, which it does by having a banking relationship with each party: collecting money from one and transfering to another. 

To be more efficient, Visa does "net settlement". Every day, each network participant's debits and credits are totalled, and at the end of the day the net money is moved once, to or from each participant.

For domestic transactions, moving money is [relatively straightforward, thanks to central banks](https://gendal.me/2013/11/24/a-simple-explanation-of-how-money-moves-around-the-banking-system/).

Crucially, Visa is also able to settle internationally, even [handling currency conversion](https://usa.visa.com/travel-with-visa/dynamic-currency-conversion.html). Visa acts as an [adapter between banking systems](https://www.bis.org/cpmi/publ/d213.pdf) with its global banking relationships. This greatly simplifies international money movement for participants in the network -- without Visa, each participant would need to manage their own international banking relationships.

<figure>
<pre class="mermaid wide">
---
config:
  theme: 'neutral'
  fontFamily: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  nodeSpacing: 20
  rankSpacing: 60
  flowchart: 
    subGraphTitleMargin: {bottom: 20}
    diagramPadding: 10
    useMaxWidth: true
---
flowchart LR
    CI[Issuer in Country A] --> VisaA["Visa's bank in A"]
    VisaB[Visa's bank in B] --> MA[Acquirer in Country B] 
    subgraph **Visa**
        VisaA -.-VisaB
    end
</pre>
<figcaption>Visa as an adapter</figcaption>
</figure>

Shuffling this amount of money around and timing everything right is no easy feat. Visa faces non-payment risk in addition to maintaining a significant balance to cover payouts while waiting to receive settlement payments. From [Visa's 2024 annual SEC report](https://investor.visa.com/SEC-Filings/default.aspx#annual-filings):

> Most U.S. dollar settlements are settled within the same day and do not result in a receivable or payable balance, while settlements in currencies other than the U.S. dollar generally remain outstanding for one to two business days, which is consistent with industry practice for such transactions. ... As of September 30, 2024, we held $11.2 billion of our total available liquidity to fund daily settlement in the event one or more of our financial institution clients are unable to settle, with the remaining liquidity available to support our working capital and other liquidity needs.

> The Company’s settlement exposure is limited to the amount of unsettled Visa payment transactions at any point in time, which vary significantly day to day. For fiscal 2024, the Company’s maximum daily settlement exposure was $137.4 billion and the average daily settlement exposure was $84.3 billion.

# 3. Set incentives

The key to this whole arrangement are the fees required to participate in the network, largely set by the network.

Let's walk through a typical credit card transaction in the US:

1. A cardholder pays for a product at a merchant.
2. The merchant pays 2.5% of the transaction to their payment processor or merchant acquirer. The 2.5% is the **merchant discount rate** or MDR.
3. The payment processor keeps 0.35%, then pays 2% to the cardholder's issuing bank and 0.15% to card network. The 2% is the *interchange fee*, commonly known as **interchange**. The 0.15% is the **network assessment fee**. [^interchange-name]
4. The issuing bank keeps 2%!

Surprisingly, the issuing bank keeps most and the network takes the least, by an order of magnitude! This is because the issuer is traditionally considered to take on most of the risk (although merchants are likely to disagree).

In addition to [regulatory requirements](https://www.consumerfinance.gov/rules-policy/regulations/1005/6/), Visa and Mastercard offer zero-liability protection. This means that the issuing bank, not the cardholder, is liable for any charges made on a card if it is lost or stolen.[^friendly-fraud] The issuing bank also takes on [credit risk](https://en.wikipedia.org/wiki/Credit_risk), and must always pay for an approved transaction even if a cardholder cannot pay off their balance.

[^friendly-fraud]: Although this creates trust in card payments, it has opened the doors to *friendly fraud*, where legitimate purchases are reported as fraudulent. Not to mention a [moral hazard](https://en.wikipedia.org/wiki/Moral_hazard).

[^interchange-name]: Although *interchange* is short for *interchange fee*, technically *interchange* refers to the payment messages being routed by the card networks, and the fee is provided for that data. But, you almost never hear *interchange* used to mean payment messages except in technical specs. 

Because of how much is given to the issuers, there are a lot of incentives for issuers to acquire customers and fund lavish rewards programs to encourage spending. This split also explains the recent rise of **issuing processors**, which make it easier for neobanks and fintechs to issue cards to access a more lucrative end of the market.

Why do merchants pay this fee? The idea is that accepting card payments yields higher spending and increased volume, in part due to credit card rewards.

<figure>
<pre class="mermaid wide">
---
config:
  theme: 'neutral'
  fontFamily: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  nodeSpacing: 10
  rankSpacing: 100
  flowchart: 
    subGraphTitleMargin: {bottom: 20}
    diagramPadding: 10
    useMaxWidth: true
---
graph LR
    I[Issuers get more interchange] --> R["Issuers more rewards and cards"]
    R --> C
    C[People spend more on cards] --> M[More merchants accept cards]
    M --> I
    %% invisible connections to make it more round
    C ~~~ I
    R ~~~ M
    R ~~~ I
    R ~~~ C
</pre>
<figcaption>The virtuous cycle of spending</figcaption>
</figure>

Out of these, the network sets the interchange and network assessment fee. Interchange fees vary dramatically based on the kind of card, category of spend, and even the metadata attached to a transaction. The networks goal is to set fees that incentivize desired behaviors on their network, including using more secure payment methods (lowering interchange fees for merchants), or for companies to do more business spending (higher interchange fees on commercial credit cards).

More cards means more merchants, more merchants mean more cards. In theory, the network benefits through fees, the merchants benefit through more purchases, and the consumer benefits through convenience.

In the EU, [interchange fees are restricted to 0.3%](https://www.psr.org.uk/our-work/card-payments/the-ifr/), which explains the lack of rewards cards and wider acceptance of alternative payment methods like bank payments.

# 4. Set rules and handle disputes







In another article, they claim to have [a moat](https://web.archive.org/web/20120330102616/https://www.usatoday.com/tech/news/story/2012-03-25/visa-data-center/53774904/1/) protecting the data center.





> "Inside the pods, 376 servers, 277 switches, 85 routers and 42 firewalls--all connected by 3,000 miles of cable--hum around the clock, enabling transactions around the globe in near real-time and keeping Visa's business running."

> "Inside the pods, 376 servers, 277 switches, 85 routers and 42 firewalls--all connected by 3,000 miles of cable--hum around the clock, enabling transactions around the globe in near real-time and keeping Visa's business running."

[Top secret Visa data center banks on security, even has moat (USA Today, 2013)](https://web.archive.org/web/20120330102616/https://www.usatoday.com/tech/news/story/2012-03-25/visa-data-center/53774904/1/)

the crux of their operation is an electronic one, and


In a typical transaction, the merchant pays 2.5% of the transaction to the payment processor. This actually the **merchant discount rate**, and includes the payment processor's cut on top of the interchange.

The payment processor keeps 0.35%, then pays 2.15% 

https://www.complexsystemspodcast.com/episodes/credit-card-rewards-interchange/