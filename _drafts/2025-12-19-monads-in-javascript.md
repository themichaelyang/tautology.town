---
layout: post
title: "Monads in the Javascript you know"
---

I finally understand monads, and now I can't stop [seeing them everywhere](https://en.wikipedia.org/wiki/Frequency_illusion). 

Javascript is full of monads.

- Promises are *almost* monads (and functors) via `.then()`.
- `async/await` is [do-notation](https://en.wikibooks.org/wiki/Haskell/do_notation) for Promises.
- The [optional chaining operator](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Optional_chaining) (`?.`) almost makes property access a [Maybe](https://wiki.haskell.org/Maybe) monad.
- Arrays are functors via `.map()`. They are also monads via `.flatMap()`, but we usually don't use them in that way.

These apply to analagous features in other languages, like Futures and `await` in Python, and the safe navigation operator (`&.`) in Ruby.

Amazingly, using monads never required [libraries](https://github.com/fantasyland/fantasy-land?tab=readme-ov-file) or writing Javascript like Haskell. We have been enjoying monads this whole time!

## Monad refresher

I'll spare you my attempt to explain monads from the ground up for now (that's for a future post) and assume you know --- approximately --- what a monad is. 

If not, you have [a couple options](https://wiki.haskell.org/Monad_tutorials_timeline). I think [this talk](https://vimeo.com/97344498) is a nice place to start. Then you can return to this post.

### Definition

Here's a definition from [Walder (1992)](https://homepages.inf.ed.ac.uk/wadler/papers/marktoberdorf/baastad.pdf#page=7), adapted to Typescript-ish syntax.

{% card %}

A *monad* is the triple (`M`, `unit`, `bind`), consisting of a type `M` and two operations matching the following type signatures:
1. `M<T>` is a generic type `M` with type parameter `T`.
2. `unit: (a: A) => M<A>`, meaning `unit` takes any type `A` and returns an `M<A>`. 
3. `bind: (m: M<A>, fn: (a: A) => M<B>) => M<B>`, meaning `bind` has two parameters, one of type `M<A>` and a function from `A` to `M<B>`. `bind` returns an `M<B>`.

{% endcard %}

{% card %}

The operations of a monad satisfy three laws:

1. **Left unit.** Compute the value `a`, bind `b` to the result, and compute `n`. The result is the same as `n` with value `a` substituted for variable `b`:
`bind(unit(a), (b) => n(b)) == n(a)`  
`bind(unit(a), f) == f(a)`

2. **Right unit.** Compute `m`, bind the result to `a`, and return `a`. The result is the same as `m`:   
`bind(m, (a) => unit(a)) == m`

3. **Associative.** Compute `m`, bind the result to `a`, compute `n`, bind the result to `b`, compute `o`. The order of parentheses in such a computation is irrelevant:  
`bind(m, (a) => bind(n(a), (b) => o(b)))` `==` `bind(bind(m, (a) => n(a)), (b) => o(b))`

{% endcard %}

A *functor* is similar, but with `map: (m: M<A>, fn: (a: A) => B)) => M<B>` instead of `bind`. A `map` can be defined from a `bind`, so all monads have equivalent functors.

We use function signatures here, but `bind` and `map` are traditionally thought of as [operators](https://en.wikipedia.org/wiki/Binary_operation) on `m` and `fn`.

### Purpose

Monads and functors are a functional programming design pattern to compose inner type functions on a generic type:
- `bind` and `map` apply a function of the inner type of a generic (`A` of `M<A>`) to an object of that generic type.
- `bind` and `map` produce an object of the generic type `M` that is also one of their input types, so they can be composed.

We can interpret `map` as a composable way of applying transformations of the inner type, preserving the shape of the input. 

Similarly, we can interpet `bind` as a composable way of applying a computation. Computations on the inner type values produce new "monadic contexts" that are merged into the input context.

## 1. Promises are almost monads (and functors) via `.then()`.

```typescript
bind(m, (a) => {
  return bind(n(a), (b) => {
    return o(b)
  })
}) 

bind(
  bind(m, (a) => {
    return n(a)
  }),
  (b) => o(b)
)
```

```typescript
// m ⋆ (λa. n ⋆ λb. o) 
bind(
  m,
  (x) => bind(f1(x), f2)
)

// (m ⋆ λa. n) ⋆ λb. o
bind(
  bind(m, f1),
  f2
)

bind(
  m, 
  (a) => bind(n(a), fn)
) 

bind(
  bind(m, (a) => n(a)),
  fn
)

m.bind(a => n(a).bind(b => o(b)))

m.bind(a => n(a))
 .bind(b => o(b))
```

In the middle of writing this post, I came across this amazing post: https://rybicki.io/blog/2023/12/23/promises-arent-monads.html that also, like this post, uses Typescript for the monad definition, but proves that Promises *aren't* Monads!

However, if we restrict our look of `then` to when it takes a function that returns a singly nested Promise, it does satisfy the signature. But that violates the formal definition. Maybe if we wrapped Promise in a "monadic adapter".

Also, conditional property access isn't a true monad either because it can't take arbitrary functions. I like the idea of monads being a property of a type, which is why `M<A> = A | null` *can* be a valid monad ("Maybe" doesn't have to be a specific object, unless you want methods) (Is this true? Then you no longer have the ability to operate on a `null` value you expected. Double check monad laws...)

These do show the power of the monadic function signature, which gives us the chainable benefit, which is in the "spirit" of monads. I think I was trying too hard to use the formal definition of monads, which is stricter. 

I'll revisit this post in the future.
