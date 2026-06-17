---
layout: post
title: "A few reasons to like Ruby"
---

<!-- TODO: vendor these! -->
<script src="https://cdn.opalrb.com/opal/current/opal.js"></script>
<script src="https://cdn.opalrb.com/opal/1.8.3/native.js"></script>
<script src="https://cdn.opalrb.com/opal/current/opal-parser.js"></script>

<script>

const template = (index, snippet) => `
  require 'native'
  
  def puts(s)
    $$.putsOverride(${index}, s)
  end
  
${snippet}
`

let consoles = []

function putsOverride(i, text) {
  consoles[i].appendChild(document.createTextNode(text + "\n"))
}

window.onload = () => {
  const pres = Array.from(document.querySelectorAll('pre'))

  pres.map((pre, i) => {
    const code = pre.textContent
    const consoleElement = document.createElement('pre')
    pre.parentNode.appendChild(consoleElement)
    consoles.push(consoleElement)
    Opal.eval(template(i, code))
  })
}

</script>

<script type="text/ruby">
  puts "hi"
</script>


[Ruby](https://www.ruby-lang.org/en/) is my favorite programming language.

I have worked in Python, Javascript (Typescript also), and Go. I have written C, C++, Java, and Racket. Consistently, Ruby is the language I enjoy the most.

It's rare to find others who feel the same. Ruby has [fallen](https://trends.google.com/explore?q=%2Fm%2F06ff5&date=all&geo=US) from the zeigeist, and developers aren't as interested in learning it anymore. At [Recurse Center](https://www.recurse.com) last year, I was the only one writing any Ruby. 

I like Ruby because it feels "good in the hand". It is hard to explain, as are all matters of taste, or beauty. I believe Ruby should still have wide appeal as something well crafted, in the same way people obsess over a really nice pen or mechanical keyboards.

Here are a few reasons to like Ruby.

## Ruby wants you to be happy

> For me, the purpose of life is, at least partly, to have joy. Programmers often feel joy when they can concentrate on the creative side of programming, so Ruby is designed to make programmers happy.
>
> – Matz, the creator of Ruby, in [2000](https://web.archive.org/web/20080220073029/http://www.informit.com/articles/article.aspx?p=18225)

Ruby is designed to make you happy. This is in contrast to languages that have pragmatic goals or technical constraints, like memory safety, concurrency, or mathematical purity. 

It's a worthy and inspiring goal.

## Everything is an expression

Ruby is inspired by Lisp. Everything evaluates to a value, including `if`. For example, you can do this:

```ruby
def ordinal(n)
  suffix = if n == 1
    "st"
  elsif n == 2
    "nd"
  elsif n == 3
    "rd"
  else
    "th"
  end
  
  "#{n}#{suffix}"
end
```

In this example, assigning once makes the program's intent clearer than setting it multiple times.

## Nice ways to loop

There are many nice ways to loop.

```ruby
3.times do |i|
  puts i
end
```

```ruby
(0..2).each do |i|
  puts i
end
```

```ruby
[0, 1, 2].each do |x|
  puts x
end
```

```ruby
[0, 1, 2].each_with_index do |x, i|
  puts i
  puts x
end
```

```ruby
0.upto(2) do |i|
  puts i
end
```

## Single line if

You can use `if`  

```ruby
# def 
```

## Single line guards

## Block syntax is a nicer lambda

## Loop methods

## Method chaining



----


https://web.archive.org/web/20070209033558/http://www.linuxdevcenter.com/pub/a/linux/2001/11/29/ruby.html

Part of me gets it. It took me a while to enjoy Ruby. 

You can ship code in any language, but 

If you like programming, I think you will like Ruby.


![Ruby in dropping popularity in Google Trends](/assets/2026/ruby-google-trends.png)

People are often perplexed when I tell them this. They are even more perplexed when I tell them I have never used [Ruby on Rails](https://rubyonrails.org), that I enjoy Ruby on its own.

Still, I like Ruby.

- http://clojurescriptmadeeasy.com/blog/ruby-got-it-right.html
- https://eliseshaffer.com/2023/12/18/i-love-ruby/
- https://news.learnenough.com/ruby-optimized-for-programmer-happiness
- https://rubyonrails.org/doctrine
- https://twobithistory.org/2017/11/19/the-ruby-story.html#fn:2
<!--
```python
# Python
suffix = "th"

if n is 1:
  suffix = "st"
elif n is 2:
  suffix = "nd"
elif n is 3:
  suffix = "rd"
```

<style>
.side-by-side {
  display: flex;
  gap: 1rem;
  align-items: stretch;
}
.side-by-side div {
  flex: 1;
  min-width: auto;
}
@media (max-width: 600px) {
  .side-by-side { flex-direction: column; }
}
</style>

<div class="side-by-side" markdown="1">


</div>-->
