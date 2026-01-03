---
layout: post
title: "DOM clobbering 1Password to fix syntax highlighting"
---

**TLDR;** Add this to prevent 1Password's browser extension from [breaking syntax highlighting](https://www.1password.community/discussions/developers/1password-chrome-extension-is-incorrectly-manipulating--blocks/165639/replies/165982) on your site:

```html
<a hidden id="Prism"></a><a hidden id="Prism" name="manual"></a>
```

Skip to the [breakdown](#payload), or read on.

---

## Backstory

About two weeks ago, I noticed that this blog's code block syntax highlighting stopped working. This blog ([tautology.town](https://tautology.town)) uses [Jekyll](https://jekyllrb.com/), which comes with [Rouge](https://github.com/rouge-ruby/rouge) syntax highlighting out of the box.

Eventually, I discovered that 1Password's browser extension was inadvertently overriding syntax highlighting in all websites ([bug report](https://www.1password.community/discussions/developers/1password-chrome-extension-is-incorrectly-manipulating--blocks/165639/replies/165982)). In a recent update, 1Password added [Prism.js](https://prismjs.com/) to support code highlighting in [rich text snippets in vaults](https://1password.com/blog/product-update-features-and-security-q3-2024#:~:text=In%20labs%3A%20Generate%20and%20fill%20formatted%20content%20with%20secure%20snippets).

Prism.js [highlights everything by default](https://prismjs.com/#manual-highlighting), so bundling it into a content script without `Prism.manual = true` means it will automatically run on every `.language-*` class code blocks on every website (since 1Password injects the content script on every site).

The immediate fix for 1Password is simple: `Prism.manual = true` and manually invoke Prism.

More importantly, Prism.js should not be in the content script at all. The feature restricted to the 1Password vault, so Prism should only be in the [extension action popup script](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/user_interface/Popups). It seems like a major oversight for this to have been included.

I assumed this would be fixed quickly.

## Some time later

Two weeks later, the issue was still not fixed and even managed to pick up [quite a bit of attention online (2.6k likes)](https://x.com/youyuxi/status/2005904473332564339):

{% card %}

youyuxi: .@1Password browser extension is injecting Prism.js *globally* on every page, which then applies its syntax highlighting logic on all \<code> blocks matching [lang=*] regardless of whether it’s meant to be compatible, thus breaking original highlighting.

Terrible negligence and even more so that this made to prod while already flagged during beta.

Been a user for a long time but this will def push me to an alternative if not fixed soon.

{% endcard %}

Evan You (@youyuxi) is the creator of Vue and Vite.

I think this was the push for 1Password to act and they are presently [deploying a fix](https://www.1password.community/discussions/developers/1password-chrome-extension-is-incorrectly-manipulating--blocks/165639/replies/165982) and promise a postmortem.

At time of writing, the fix is not yet live for me. I see an update in the Chrome store, but not in Firefox or Safari.

While we wait, we can take matters into our own hands.

## DOM clobbering

Web extension content scripts get access to the DOM (to do stuff) but run in an [isolated Javascript context](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Content_scripts#dom_access) to prevent web content from accessing or overriding their behavior. Without this, they could be vulnerable to something like [prototype pollution](https://developer.mozilla.org/en-US/docs/Web/Security/Attacks/Prototype_pollution).

However, access to the DOM is still susceptible to an attack called *DOM clobbering*. 

The HTML standard allows for "named property access" on `window` ([docs](https://developer.mozilla.org/en-US/docs/Web/API/Window#named_properties)) and `document` ([docs](https://developer.mozilla.org/en-US/docs/Web/API/Document#named_properties)), which means HTML DOM elements with `id` or `name` set can be accessed as properties. For `window`:

> For each \<embed>, \<form>, \<iframe>, \<img>, and \<object> element, its name (if non-empty) is exposed. For example, if the document contains \<form name="my_form">, then window\["my_form"] (and its equivalent window.my_form) returns a reference to that element.  
>
> For each HTML element, its id (if non-empty) is exposed.  
>
> If a property corresponds to a single element, that element is directly returned. If the property corresponds to multiple elements, then an HTMLCollection is returned containing all of them. If any of the elements is a navigable \<iframe> or \<object>, then the contentWindow of first such iframe is returned instead.


Even DOM APIs like `document.addEventListener` can be overridden in this way.

There are some limitations to this attack:
- It only works if the corresponding value is not already defined by the Javascript context.
- You can only return HTML elements or an `HTMLCollection`, not arbitrary values.

Still, you can take advantange of things like:
- `HTMLCollection` access by id/name to [DOM clobber nested properties](https://aszx87410.github.io/beyond-xss/en/ch3/dom-clobbering/#nested-dom-clobbering).
- HTML elements are truthy, so you can override false values.
- `<a>` tags `toString()` gives the `href` value, and can be coerced with concatenation.
- Convenient property access that matches HTML elements: e.g. if `value` is accessed you can clobber with an `<input>` you can override that access with a string.

We can use the first two tricks to clobber 1Password's Prism.js.

## Clobbering Prism.js

If Prism.js was injected unsafely, it would be sufficient to use this snippet from their docs to disable auto-highlighting:

```html
<script>
window.Prism = window.Prism || {};
window.Prism.manual = true;
</script>
```

Since 1Password's content script is in an isolated context, this script won't affect it and its Prism.js won't ever see  `window.Prism.manual = true`.

Let's look at the Prism.js source to see how this is evaluated. On [line 51 of](https://github.com/PrismJS/prism/blob/298b75f1764c4abfe76d997394b7b149845f685a/components/prism-core.js#L51) `prism-core.js`: 

```javascript
manual: _self.Prism && _self.Prism.manual,
```

It's checked [on line 1184](https://github.com/PrismJS/prism/blob/298b75f1764c4abfe76d997394b7b149845f685a/components/prism-core.js#L1184C2-L1184C18) before auto-highlighting:

```javascript
if (!_.manual) {
````

And `_self` is set [on line 3](https://github.com/PrismJS/prism/blob/298b75f1764c4abfe76d997394b7b149845f685a/components/prism-core.js#L3):

```javascript
var _self = (typeof window !== 'undefined')
	? window   // if in browser
	: (
		(typeof WorkerGlobalScope !== 'undefined' && self instanceof WorkerGlobalScope)
			? self // if in worker
			: {}   // if in node js
	);
```

So, `manual` is set to `window.Prism.manual` and can be DOM clobbered! Note that this would also work with`Prism.manual`, since `window` is implicit.

### Payload

Let's craft our payload and put it in our HTML:

```html
<a hidden id="Prism"></a><a hidden id="Prism" name="manual"></a>
```

We can check the console:

```javascript
> window.Prism
HTMLCollection(2) [a#Prism, a#Prism, Prism: a#Prism, manual: a#Prism]

> window.Prism.manual
<a hidden id=​"Prism" name=​"manual">​</a>​

> !window.Prism.manual
false
```

And it works! This is the fix currently deployed to this site, if you need further proof it works.

#### Breakdown

1. There are two `<a>` tags with matching `id=Prism`, so `window.Prism` will return a `HTMLCollection` of them. 
2. An HTMLCollection's elements can be accessed by `id` and `name`, so we give the second tag `name="manual"` so `manual` can be accessed as a property on the collection. 
3. Finally, an HTML element is truthy, so `!window.Prism.manual` returns `false`, stopping automatic highlighting.
4. Also, we add `hidden` so they aren't displayed anywhere + ignored by screen readers.

## Security implications

### 1Password, the app

You may be (rightfully) concerned about other ways 1Password could be DOM clobbered via Prism.js. 

In fact, I learned about DOM clobbering when checking the security implications of this leak. 

[CVE-2024-53382](https://nvd.nist.gov/vuln/detail/CVE-2024-53382) for Prism.js 1.29.0 describes an XSS using DOM clobbering. The [original report](https://gist.github.com/jackfromeast/aeb128e44f05f95828a1a824708df660) gives a great summary of the vulnerability. At a high level, Prism's autoloader plugin uses `document.currentScript` to dynamically load language definitions, but an attacker could clobber to load their own script in an `<img>`. It was patched in 1.30 by checking if `document.currentScript.tagName` equals `'SCRIPT'`.

As far as I could tell, the version deployed by 1Password is not vulnerable to XSS via Prism. The `manual` parameter is designed to be overridden in a weird way, which inadvertently allows for DOM clobbering. Other things on Prism don't appear to be clobberable.

I did discover some potential XSS vulnerabilities in v2 of Prism.js. That version has been in development [since 2022](https://github.com/orgs/PrismJS/discussions/3531) and is the [default branch on GitHub](https://github.com/PrismJS/prism), but isn't yet released. I'll submit a change or report to those soon after I finish my investigation.

### 1Password, the company

The bigger question is what this signals about 1Password, the company.

I've historically trusted 1Password over other password managers due to their secret key based security model and nicer design (especially over [LastPass](https://en.wikipedia.org/wiki/LastPass#Security_Criticism), which regularly has security incidents).

This incident has made me reconsider. I don't think it should have been addressed so slowly (2+ weeks), nor should it have been made it past code review. Adding stuff to the content script is a pretty big deal for extension development.

Security is largely a function of [organizational culture](https://google.github.io/building-secure-and-reliable-systems/raw/ch21.html) and this does not reflect well on that culture. We'll find out more if/when they publish the postmortem.

Let's hope I'm wrong. Trust is easy to lose and hard to gain back.

---

## Resources

- I like this writeup of DOM clobbering best: [Beyond XSS: Can HTML affect JavaScript? Introduction to DOM clobbering](https://aszx87410.github.io/beyond-xss/en/ch3/dom-clobbering/)
- A useful table of common patterns: [DOM Clobbering Wiki: Patterns and Guidelines](https://domclob.xyz/domc_wiki/indicators/patterns.html)
- Another developer's very similar experience: [1Password Dependency Breaks Syntax Highlighting
](https://borretti.me/article/1password-dependency-breaks-syntax-highlighting)

You might also find interesting the WHATWG specs for named properties:
- [7.2.2.3 Named access on the Window object](https://html.spec.whatwg.org/multipage/nav-history-apis.html#named-access-on-the-window-object:window-3)
- [3.1.6 DOM tree accessors](https://html.spec.whatwg.org/multipage/dom.html#dom-document-namedItem-which)

<!--
>Some elements in the document are also exposed as properties:
>
>For each \<embed>, \<form>, \<iframe>, \<img>, and \<object> element, its name (if non-empty) is exposed. For example, if the document contains \<form name="my_form">, then document\["my_form"] (and its equivalent document.my_form) returns a reference to that element.
>
>For each \<object> element, its id (if non-empty) is exposed.
>
>For each \<img> element with non-empty name, its id (if non-empty) is exposed.
>
>If a property corresponds to a single element, that element is directly returned. If that single element is an iframe, then its contentWindow is returned instead. If the property corresponds to multiple elements, then an HTMLCollection is returned containing all of them.

-->
