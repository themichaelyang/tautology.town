---
layout: post
title: "A few reasons to like Ruby"
---


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
  /*padding: 0.5rem;*/
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
  .toc { columns: 1; }
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

.toc {
  columns: 2;
}

.toc ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

</style>


[Ruby](https://www.ruby-lang.org/en/) is my favorite programming language.

I have worked in Python, Javascript (Typescript also), and Go. I have written C, C++, Java, and Racket. Consistently, Ruby is the language I enjoy the most.

I like Ruby because it feels "good in the hand". It is hard to explain, as are all matters of taste, or beauty. I believe Ruby ought to be appreciated like anything else well crafted, the way people obsess over a really nice pen or mechanical keyboards.


It's rare to find others who feel the same. Ruby has [fallen](https://trends.google.com/explore?q=%2Fm%2F06ff5&date=all&geo=US) from the zeitgeist, and developers aren't as interested in learning it anymore. At [Recurse Center](https://www.recurse.com) last year, I was the only one writing any Ruby. 

For the unacquainted, here are a few reasons to like Ruby:

<div class="toc" markdown="1">

- [0. Ruby wants you to be happy](#0-ruby-wants-you-to-be-happy)
- [1. Expressions everywhere](#1-expressions-everywhere)
- [2. Looping with numbers](#2-looping-with-numbers)
- [3. Better lambdas with blocks](#3-better-lambdas-with-blocks)
- [4. Enumerating is easy](#4-enumerating-is-easy)
- [5. Method pipelines](#5-method-pipelines)
- [6. Combinatorics](#6-combinatorics)
- [7. Single line if](#7-single-line-if)
- [8. Meaningful punctuation](#8-meaningful-punctuation)
- [9. Modules are namespaces](#9-modules-are-namespaces)
- [10. `until`](#10-until)
- [11. Do what works for you](#11-do-what-works-for-you)

</div>

## Run the code

All the code snippets in this post run in your browser thanks to [Opal](https://opalrb.com). You can edit them too. Note that there are [differences](https://github.com/opal/opal/blob/abf15821c36dbc0fbc04ad53226deeb156c669d8/docs/unsupported_features.md?plain=1#L9) between Opal and Ruby, but they shouldn't matter here.

It's okay if you don't know any Ruby (and even better if you're new). You should be able to follow along if you know any modern mainstream language. More important than the language rules, I hope you get a sense of what Ruby is *like*.

## [0. Ruby wants you to be happy](#0-ruby-wants-you-to-be-happy)

> For me, the purpose of life is, at least partly, to have joy. Programmers often feel joy when they can concentrate on the creative side of programming, so Ruby is designed to make programmers happy.
>
> – Matz, the creator of Ruby, in [2000](https://web.archive.org/web/20080220073029/http://www.informit.com/articles/article.aspx?p=18225)

Languages are, in part, philosophical endeavours and are imbued with their creators' values. Matz has a particular philosophy --- Ruby is designed to make you happy. 

This is in contrast to languages that have pragmatic goals or technical constraints, like memory safety, concurrency, or mathematical purity.

It's a worthy and inspiring goal, and the single best reason to try out Ruby.

## [1. Expressions everywhere](#1-expressions-everywhere)

Ruby is inspired by Lisp (everyone admires Lisp, right?). Everything evaluates to a value, including `if`-`else`. Functions return their last expression. 

For example, you can do this:

```ruby
# <- hashes start comments
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

  # functions return last expression
  "#{n}#{suffix}"
end

puts ordinal(1) # puts is Ruby for print
puts ordinal(2)
puts ordinal(3)
puts ordinal(4)
# all the code snippets are editable! 
# uncomment me and run again
# puts ordinal(5)
```

Assigning `suffix` once makes the program's intent clearer than setting it multiple times. 

## [2. Looping with numbers](#2-looping-with-numbers)

Numbers are objects and expose some wonderful methods for looping.

```ruby
3.times do |i|
  puts i
end

0.upto(2) do |i|
  puts i
end
```


## [3. Better lambdas with blocks](#3-better-lambdas-with-blocks)

Also [inspired by Lisp](https://www.artima.com/articles/blocks-and-closures-in-ruby), Ruby has a dedicated and elegant syntax for lambdas. This is the `method_name do |variables| ... end` and the abbreviated `method_name { |variables| ... }` above. It's a "block" of code (a closure) that is passed like a lambda into `method_name` to be invoked within. `|variables|` can be omitted if the block takes no arguments. 

In the loop examples above, we've been passing blocks into loop methods that are invoked once per iteration.

You can use them for:
- context and resource management (`with` in Python)
- [middlewares](https://github.com/rack/rack)
- iterators/generators
- domain specific languages (DSL)

For example, a helper to [benchmark](https://github.com/ruby/benchmark) code:

```ruby
def stopwatch(&blk) # &blk means accept a block
  start = Time.now
  ret = yield # yield runs the block!
  finish = Time.now

  [ret, finish - start]
end

arr, duration = stopwatch do 
  10000.times.map do
    rand(100)
  end
end

puts "array of #{arr.length} random numbers"
puts "took #{duration} seconds to make\n\n"
puts "first five: #{arr.take(5)}"
```

Or a compact DSL for [testing](https://github.com/minitest/minitest):

```ruby
def test(desc, &blk)
  puts "Test: #{desc}"
  @checks, @failed = 0, 0 # @variables are instance vars
  
  yield # run test cases

  if @failed == 0
    puts "[✓] All #{@checks} passed!\n\n"
  else
    puts "[x] #{@failed} / #{@checks} failed!\n\n"
  end
end

def expect(actual, expected)
  if expected != actual
    @failed += 1
    puts "=> Check ##{@checks + 1} failed: #{actual} should be #{expected}"
  end
  
  @checks += 1
end

# Can your language do this?

test "addition" do
  expect(1 + 1, 2)
  expect(2 + 3, 5)
end

test "subtraction" do
  expect(1 - 1, 0)
  expect(-1 - 1, 0) # fails!
end
```

Blocks are very natural to incorporate and use. 

## [4. Enumerating is easy](#4-enumerating-is-easy)

[Enumerables](https://docs.ruby-lang.org/en/master/Enumerable.html) (`Array`s, `Range`s, `Hash`maps, even `Prime`s) have excellent methods, many of which take blocks:
- `tally`: tallies the number of each item, my personal favorite. What a great method name!
- `map`, `reduce`: classic map/reduce
- `select`, `reject`: querying
- `include?`, `any?`, `all?`: checking for stuff
- `sort`, `sort_by`: passing a block can change what it sorts with
- `take(n)`: takes `n` elements
- `each_cons(n)`: sliding window of `n` elements
- `each_slice(n)`: tumbling window of `n` elements
- `chunk`: takes a block and groups each chunk by the return value
- `lazy` switches an iterator to lazy evaluation

These methods are designed to be chained and return another Enumerable. 

```ruby
years = (2020..2025).map do |yr|
  {
    year: yr, 
    leap: (yr % 4 == 0 && yr % 100 != 0) || yr % 400 == 0
  }
end

days = years.map { |hash| hash[:leap] }
            .sum { |leap| leap ? 366 : 365 }

puts "#{days} days"
```

## [5. Method pipelines](#5-method-pipelines)

A nice part of Javascript is method chaining. This is a good style for data being piped through a series of transforms. Ruby does this even better because: 
- everything is an object
- everything is an expression and returns an object
- objects come with many useful methods
- blocks simplify lambdas
- optional punctuation — methods without arguments can omit parens. No need for a [pipe operator](https://github.com/tc39/proposal-pipeline-operator)!

```ruby
def commas(num)
  num.to_s.chars.reverse
    .each_slice(3).map(&:join)
    .join(',').reverse
end

puts commas(1234567890)
```

Powerful methods compose into powerful pipelines.

```ruby
gatsby = "In my younger and more vulnerable years my father 
gave me some advice that I've been turning over in my mind 
ever since. \"Whenever you feel like criticizing anyone,\" 
he told me, \"just remember that all the people in this world
haven't had the advantages that you’ve had.\""

bigrams = gatsby.delete("\'\".\n").downcase.split.flat_map do |word|
  # every 2 consecutive char in the words
  word.chars.each_cons(2).to_a
end

# hashmap sorted as a list of pairs sorted by last item (the value)
top_bigram = bigrams.tally.sort_by(&:last).last

puts "most common bigram: \"#{top_bigram.first.join}\""
puts "seen #{top_bigram.last} times"
```

## [6. Combinatorics](#6-combinatorics)

There are even methods to shuffle, permute, combine, and sample.

```ruby
values = ["ace"] + (2..10).to_a + ["jack", "queen", "king"]
suits = ["spade", "heart", "club", "diamond"]
colors = { 
  "spade" => "black", "heart" => "red",
  "club" => "black", "diamond" => "red"
}

deck = values.product(suits)
puts "a deck has #{deck.count} cards\n\n"

drawn = deck.shuffle.take(2)
hand = drawn.map do |value, suit|
  "a #{colors[suit]} #{value} of #{suit}s"
end

puts "you drew #{hand.join(" and ")}"
```

```ruby
possible = ["H", "T"].repeated_permutation(4).to_a
ways = possible.map(&:tally).tally

outcome = possible.sample
puts "you flipped #{outcome}\n\n"
puts "that is 1 of #{ways[outcome.tally]} ways " \
 + "to get that number of heads and tails"
```

## [7. Single line if](#7-single-line-if)

A trailing `if` conditionally executes a line. Guards read nicely and emphasize early returns.

```ruby
def fib(n)
  return [0, n].max if n <= 1

  fib(n - 1) + fib(n - 2)
end

puts fib(1)
puts fib(10)
```

Most things in Ruby are expressions, but this is a statement. Ruby is flexible, not dogmatic!

## [8. Meaningful punctuation](#8-meaningful-punctuation)

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

Meanwhile parentheses are optional which is great for keeping straightforward method calls visually clean.

## [9. Modules are namespaces](#9-modules-are-namespaces)

Namespaces are always a good idea. Names resolve relative to modules or you can fully qualify names.

```ruby
module Baseball
  class Bat
  end

  EQUIPMENT = [Bat]
end

module Cave
  class Bat
  end

  ANIMALS = [Bat]
end

puts Baseball::EQUIPMENT.include?(Baseball::Bat)
puts Baseball::EQUIPMENT.include?(Cave::Bat)

puts Cave::ANIMALS.include?(Cave::Bat)
puts Cave::ANIMALS.include?(Baseball::Bat)
```


## [10. `until`](#10-until)

In addition to `while` loops, Ruby has its opposite `until` that is much nicer to read for traversals.

```ruby
Node = Struct.new(:val, :left, :right)

def dfs(root, &blk)
  stack = [root]
  
  until stack.empty?
    current = stack.pop
    
    yield current
    
    stack.push(current.right) if current.right
    stack.push(current.left) if current.left
  end
end

tree = Node.new(
  "S",
  Node.new("SL", Node.new("SLL"), Node.new("SLR")),
  Node.new("SR", Node.new("SRL"), Node.new("SRR"))
)

dfs(tree) do |node|
  puts node.val
end
```

You could do this with `while stack.length > 0` but `until stack.empty?` reads so much better.

## [11. Do what works for you](#11-do-what-works-for-you)

Ruby deliberately lets you do things many different ways so you can do what maps better to your mental model. This goes as far as making it easy to introspect and modify the language. It wants to fit your thinking, rather than wanting you to think in terms of it.

Give [Ruby a try](https://try.ruby-lang.org)!


# Links
- Rails' take on programmer happiness is [worth a read](https://rubyonrails.org/doctrine#optimize-for-programmer-happiness), as is the rest of its principles: [The Rails Doctrine](https://rubyonrails.org/doctrine)
- Matz discusses Ruby's philosophy in a series of interviews from 2003: [The Philosophy of Ruby: A Conversation with Yukihiro Matsumoto, Part I](https://www.artima.com/articles/the-philosophy-of-ruby)
- More reasons to like Ruby: [I Love Ruby (Elise Shaffer)](https://eliseshaffer.com/2023/12/18/i-love-ruby/)
- Nice tour of Ruby: [Learn Ruby in Y minutes](https://learnxinyminutes.com/ruby/)
- [About Ruby](https://www.ruby-lang.org/en/about/) in the official Ruby docs


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
  
  const setTheme = () => {
    let isDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    let theme = (isDark) ? 'solarized dark' : 'solarized light'
    editors.map(ed => ed.setOption('theme', theme))
  }

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
    
    setTheme()

    const button = document.createElement('button')
    button.className = 'run-button'
    button.textContent = 'Run'
    button.onclick = () => run(i)
    playground.appendChild(button)

    // hide before run first timer
    consoleElement.style.display = 'none'
  })

  window.matchMedia('(prefers-color-scheme: dark)')
    .addEventListener('change', () => editors.map(ed => {
      setTheme()
    })
  )

}

</script>
