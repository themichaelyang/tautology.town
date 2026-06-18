---
layout: post
title: "A few reasons to like Ruby"
---

<!-- TODO: vendor these! -->
<script src="https://cdn.opalrb.com/opal/current/opal.js"></script>
<script src="https://cdn.opalrb.com/opal/1.8.3/native.js"></script>
<script src="https://cdn.opalrb.com/opal/current/opal-parser.js"></script>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/theme/solarized.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/ruby/ruby.min.js"></script>

<script>

const template = (index, snippet) => `
  require 'native'

  def puts(*args)
    lines = args.empty? ? [""] : args.flatten.map { |a| a.to_s }
    text = lines.map { |l| l.end_with?("\\n") ? l : l + "\\n" }.join
    $$.putsOverride(${index}, text)
  end

  def p(*args)
    puts(args.map { |arg| arg.is_a?(Array) ? arg.to_s : arg })
  end

${snippet}
`


let editors = []
let consoles = []

function putsOverride(i, text) {
  consoles[i].appendChild(document.createTextNode(text))
}

function run(i) {
  consoles[i].style.display = 'block'
  consoles[i].style.animation = 'slide-left 0.1s ease-in'
  consoles[i].textContent = ''
  try {
    Opal.eval(template(i, editors[i].getValue()))
  } catch (e) {
    consoles[i].appendChild(document.createTextNode((e && e.message || e) + "\n"))
  }
}

window.onload = () => {
  const blocks = Array.from(document.querySelectorAll('div.highlight'))

  blocks.forEach((block, i) => {
    const code = block.textContent.replace(/\n+$/, '')

    const playground = document.createElement('div')
    playground.className = 'playground'
    block.parentNode.replaceChild(playground, block)

    const row = document.createElement('div')
    row.className = 'playground-row'
    playground.appendChild(row)

    const editorHost = document.createElement('div')
    editorHost.className = 'editor'
    row.appendChild(editorHost)

    const consoleElement = document.createElement('pre')
    consoleElement.className = 'console'
    row.appendChild(consoleElement)
    consoles[i] = consoleElement

    editors[i] = CodeMirror(editorHost, {
      value: code,
      mode: 'ruby',
      theme: 'solarized dark',
      lineNumbers: true,
      tabSize: 2,
      indentUnit: 2,
      viewportMargin: Infinity
    })

    const setTheme = () => {
      let isDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      let theme = (isDark) ? 'solarized dark' : 'solarized light'
      editors.map(ed => ed.setOption('theme', theme))
    }

    window.matchMedia('(prefers-color-scheme: dark)')
      .addEventListener('change', () => editors.map(ed => {
        setTheme()
      })
    )

    setTheme()

    const button = document.createElement('button')
    button.className = 'run-button'
    button.textContent = 'Run'
    button.onclick = () => run(i)
    playground.appendChild(button)

    // hide before run first timer
    consoleElement.style.display = 'none'

    // run(i)
  })
}

</script>

<style>

@keyframes slide-left {
  from {
    transform: translateX(100%);
  }
  to {
    transform: translateX(0%);
  }
}

.playground {
  display: flex;
  flex-direction: column;
  margin: 1.5rem 0;
  gap: 0.5rem;
}

.playground-row {
  display: flex;
  align-items: stretch;
  gap: 0.5rem;
  overflow: hidden;
}

/* Ruby snippet */
.playground .editor {
  flex: 3;
  min-width: 0;
  display: flex;
  flex-direction: column;
  border-radius: 4px;
  overflow: hidden;
  border: 1px solid var(--code-border);
}

.playground .editor .CodeMirror {
  flex: 1;
  height: auto;
  box-shadow: none;
  font-size: 0.8em;
  padding: 0.5rem;
  font-family: var(--code-font);
}

/* console */
.playground .console {
  flex: 1;
  min-width: 0;
  margin: 0;
  padding: 0.5rem;
  overflow: auto;
  border: none;
  border-radius: 4px;
  border: 1px solid var(--code-border);
  white-space: pre-wrap;
}

@media (max-width: 600px) {
  .playground-row { flex-direction: column; }
}

.run-button {
  font-family: inherit;
  border: 1px solid var(--code-border);
  box-shadow: inset -1px -1px 2px var(--run-code-shadow);
  background: var(--code-border);
  color: var(--run-code-text);
  border-radius: 4px;
  font-weight: bold;
  /*color: inherit;*/
  /*opacity: 0.8;*/
  font-size: 1rem;
  padding: 0.5rem 1rem;
  cursor: pointer; 
  flex: 1;
}

.run-button:active {
  box-shadow: inset 1px 1px 2px var(--run-code-shadow);
}

</style>


[Ruby](https://www.ruby-lang.org/en/) is my favorite programming language.

I have worked in Python, Javascript (Typescript also), and Go. I have written C, C++, Java, and Racket. Consistently, Ruby is the language I enjoy the most.

I like Ruby because it feels "good in the hand". It is hard to explain, as are all matters of taste, or beauty. I believe Ruby should still have wide appeal as something well crafted, in the same way people obsess over a really nice pen or mechanical keyboards.

It's rare to find others who feel the same. Ruby has [fallen](https://trends.google.com/explore?q=%2Fm%2F06ff5&date=all&geo=US) from the zeigeist, and developers aren't as interested in learning it anymore. At [Recurse Center](https://www.recurse.com) last year, I was the only one writing any Ruby. 

For the uninitiated, here are a few reasons to like Ruby.

## Before we begin

All the code snippets in this post can be run locally thanks to [Opal](https://opalrb.com). You can edit them too. Note that there are some [differences](https://github.com/opal/opal/blob/abf15821c36dbc0fbc04ad53226deeb156c669d8/docs/unsupported_features.md?plain=1#L9) between Opal and Ruby, including some of the standard libraries.

Also, it's okay if you don't know any Ruby -- you should be able to follow if you know any mainstream language of today. I hope you get a better sense of what it's like to use Ruby and convince you to give it a try.

## 0. Ruby wants you to be happy

> For me, the purpose of life is, at least partly, to have joy. Programmers often feel joy when they can concentrate on the creative side of programming, so Ruby is designed to make programmers happy.
>
> – Matz, the creator of Ruby, in [2000](https://web.archive.org/web/20080220073029/http://www.informit.com/articles/article.aspx?p=18225)

Languages are, in part, philosophical endeavours and are imbued with their creators' values. Ruby is designed to make you happy. 

This is in contrast to languages that have pragmatic goals or technical constraints, like memory safety, concurrency, or mathematical purity. Rails' take on this is [worth a read](https://rubyonrails.org/doctrine#optimize-for-programmer-happiness).

It's a worthy and inspiring goal, and the single best reason to try out Ruby.

## 1. Expressions everywhere

Ruby is inspired by Lisp. Everything evaluates to a value, including `if`-`else`. For example, you can do this:

```ruby
# <- hashes start comments
# functions return their last expression
def ordinal(n)
  suffix = if n == 1 && n != 11
    "st"
  elsif n == 2 && n != 12
    "nd"
  elsif n == 3 && n != 13
    "rd"
  else
    "th"
  end

  "#{n}#{suffix}"
end

puts ordinal(1) # puts is Ruby for print
puts ordinal(2)
puts ordinal(3)
puts ordinal(4)
```


Assigning `suffix` once makes the program's intent clearer than setting it multiple times. 

## 2. Punctuation in method names

Question marks `?` are a nice touch for methods that return booleans, and read nicely in English.

```ruby
planets = [
  "Mercury", "Venus", "Earth", "Mars", 
  "Jupiter", "Saturn", "Uranus", "Neptune"
]

puts planets.include? "Pluto"
puts planets.empty?
puts planets.any? { |p| p.downcase.include?("y") }
puts planets.any? { |p| p.downcase.include?("z") }
```

Exclamation points `!` are used for methods that modify an object in-place or throw errors.

## 4. Looping with numbers

Numbers are objects and expose some wonderful methods for looping.

```ruby
3.times do |i|
  puts i
end

0.upto(2) do |i|
  puts i
end
```

## 5. Block syntax for cleaner lambdas

Ruby has more than first class functions, it has dedicated and elegant syntax for lambdas. This is the `method_name do |variables| ... end` and the abreviated `method_name { |variables| ... }` above. It's a "block" of code (a closure) that is passed like a lambda into `method_name` to be invoked within. `|variables|` can be omitted if the block takes no arguments. 

In the loop examples above, we've been passing blocks into loop methods that are invoked once per iteration.

You can use them for:
- context and resource management (`with` in Python)
- [middlewares](https://github.com/rack/rack)
- iterators/generators
- domain specific languages (DSL)

For example, a helper to [benchmark](https://github.com/ruby/benchmark) code:

```ruby
def timed(&blk) # &blk means accept a block
  start = Time.now
  ret = yield # yield runs the block!
  finish = Time.now

  [ret, finish - start]
end

arr, timing = timed do 
  10000.times.map do
    (Random.random_number * 100).floor
  end
end

puts "array of #{arr.length} random numbers"
puts "took #{timing} seconds"
puts "first five: #{arr.take(5)}"
```

Or a compact DSL for [testing](https://github.com/minitest/minitest):

```ruby
module Testing
  def test(desc, &blk)
    @in_test = true
    @cases, @failures = 0, []
    yield 

    puts "Test: #{desc}"
    if @failures.empty?
      puts "All #{@cases} passed!"
    else
      puts "#{@failures.length} / #{@cases} failed!"
      @failures.each { |f| puts f }
    end
    puts ""
    @in_test = false
  end

  def expect(expected, actual)
    raise "not a test" unless @in_test
    if expected != actual
      @failures << "> Case #{@cases + 1}: " + \
        "#{actual} should be #{expected}"
    end
    @cases += 1
  end
end

# And in use:
include Testing

test "Array#any?" do
  expect([false, false, false].any?, false)
  expect([false, false, true].any?, true)
end

test "Array#all?" do
  expect([true, true, true].all?, true)
  expect([true, true, false].all?, false)
end

test "a is b" do
  expect("a", "a")
  expect("a", "b")
end
```

Blocks are very natural to incorporate and use. 

## 6. Enumerable

Enumerable methods (`Array`s, `Range`, `Hash` maps, even `Prime`s) have excellent methods like `each`, `map`, `with_index`, `count`, `tally`, `select`, `reject`, `any?`, `all?`, `take`, `each_cons`, `max`, `min`, `sort`, etc.

These methods are designed to be chained by returning another Enumerable. For example, `lazy` can be chained to switch an iterator to lazy evaluation.

```ruby
years = (2020..2025).map do |yr|
  [yr, (yr % 4 == 0 && yr % 100 != 0) || yr % 400 == 0]
end

days = years.sum { |_yr, leap| leap ? 366 : 365 }
puts days
```

## 7. Method pipelines

One of the popular parts of Javascript is method chaining. Ruby does this even better: everything is an object (and returns an object), way more useful methods, blocks simplify lambdas, punctuation can be omitted. Pipe everything through a series of composable, high-level methods.

It's concise and powerful, yet stays readable.

```ruby
pan = "The quick brown fox jumps over the lazy dog"
puts cfreq = pan.downcase.delete(" ").chars.tally

bigrams = pan.downcase.split.flat_map do |word|
  # every 2 conseq char in the words
  word.chars.each_cons(2).to_a
end

# hashmap sorted as a list of pairs, sorted by last item (the value)
top_bigram = bigrams.tally.sort_by(&:last).last

puts "top: #{top_bigram.first}, #{top_bigram.last} times"
```

## 8. Single line if

You can use a trailing `if` to conditionally execute a line (one of the few statements in Ruby). This can be used for compact function guards that read nicely by emphasizing early returns.

```ruby
def fib(n)
  return [0, n].max if n <= 1

  fib(n - 1) + fib(n - 2)
end

puts fib(10)
puts fib(-1)
```

## 9. Modules as namespaces

Namespaces are always a good idea. As are fully-qualified-names.

## 10. until

In addition to `while`, Ruby has `until` which is much nicer to read for traversals.

## 11. Combinatorics

You can shuffle, permute, and combine.

```ruby
```

----

Links
- https://web.archive.org/web/20070209033558/http://www.linuxdevcenter.com/pub/a/linux/2001/11/29/ruby.html
- http://clojurescriptmadeeasy.com/blog/ruby-got-it-right.html
- https://eliseshaffer.com/2023/12/18/i-love-ruby/
- https://news.learnenough.com/ruby-optimized-for-programmer-happiness
- https://rubyonrails.org/doctrine
- https://twobithistory.org/2017/11/19/the-ruby-story.html#fn:2
- https://learnxinyminutes.com/ruby/
- https://www.ruby-lang.org/en/about/

<!--There are many nice methods for looping on objects.

```ruby
# 0..2 is a range from 0 to 2, inclusive
(0..2).each do |i|
  puts i
end
```

Exclamations `!` is the convention for methods that mutate an object in-place, or error. They're often paired with non in-place variants (without `!`).

```ruby
a = [1, 2, 3]
p a
```

```ruby
# <- hashes start comments
# functions return last expression
def ordinal(n)
  
  suffix = if n == 1 && n != 11
    "st"
  elsif n == 2 && n != 12
    "nd"
  elsif n == 3 && n != 13
    "rd"
  else
    "th"
  end
  
  "#{n}#{suffix}"
end

puts ordinal(3)
```
Blocks [go beyond](https://tech.stonecharioteer.com/posts/2025/ruby-blocks/) callbacks:
-->
