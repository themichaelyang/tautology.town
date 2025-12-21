---
layout: post
title: "Monads in the Javascript you know"
---

I finally understand monads, and now I can't stop [seeing them everywhere](https://en.wikipedia.org/wiki/Frequency_illusion). 

Javascript is full of monads.

- Promises are monads (and functors) via `.then()`.
- `async/await` is [do-notation](https://en.wikibooks.org/wiki/Haskell/do_notation) for Promise monads.
- The [optional chaining operator](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Optional_chaining) (`?.`) makes properties a [Maybe](https://wiki.haskell.org/Maybe) monad.
- Arrays are functors via `.map()`. They are also monads via `.flatMap()`, but we usually don't use them in that way.

These apply to analagous features in other languages, like Futures and `await` in Python, and the safe navigation operator (`&.`) in Ruby.

Amazingly, using monads never required [libraries](https://github.com/fantasyland/fantasy-land?tab=readme-ov-file) or writing Javascript like Haskell. We have been enjoying monads this whole time!

## Monad refresher

I'll spare you my attempt to explain monads from the ground up for now (that's for a future post) and assume you know --- approximately --- what a monad is. 

If not, you have [a couple options](https://wiki.haskell.org/Monad_tutorials_timeline). Then you can return to this post.

Here's the definition from the original monad paper [(Walder, 1992)](https://homepages.inf.ed.ac.uk/wadler/papers/marktoberdorf/baastad.pdf#page=7), adapted to Typescript-ish syntax.

### Definition

{% card %}

A *monad* is the triple (`M`, `unit`, `bind`), consisting of a type `M` and two operations matching the following type signatures:
1. `M<T>` is a generic type `M` with type parameter `T`.
2. `unit: (a: A) => M<A>`, meaning `unit` takes any type `A` and returns an `M<A>`. 
3. `bind: (m: M<A>, fn: (a: A) => M<B>) => M<B>`, meaning `bind` has two parameters, one of type `M<A>` and a function from `A` to `M<B>`. `bind` returns an `M<B>`.

{% endcard %}

A *functor* is similar, but with `map: (m: M<A>, fn: (a: A) => B)) => M<B>` instead of `bind`. A `map` can be defined from a `bind`, so all monads have equivalent functors.

We use function signatures here, but `bind` and `map` are traditionally thought of as [operators](https://en.wikipedia.org/wiki/Binary_operation) on `m` and `fn`.

### Purpose

Monads and functors are a functional programming design pattern to compose inner type functions on a generic type:
- `bind` and `map` apply a function of the inner type of a generic (`A` of `M<A>`) to an object of that generic type.
- `bind` and `map` produce an object of the generic type `M` that is also one of their input types, so they can be composed.

We can interpret `map` as a composable way of applying transformations of the inner type, preserving the shape of the input. 

Similarly, we can interpet `bind` as a composable way of applying a computation. Computations on the inner type values produce new "monadic contexts" that are merged into the input context.

## Promises are monads
