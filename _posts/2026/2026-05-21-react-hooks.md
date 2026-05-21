---
layout: post
title: "How React hooks associate functions with state"
---

A question I had for a long time was: how do React hooks work?

Specifically, how do they associate a functional component with state, without requiring a stable identifier?

There are many high quality answers online. For me, they either focus to deeply on React internals ([Fibers](https://stackoverflow.com/a/53730788/7971276), [render cycle](https://eliav2.github.io/how-react-hooks-work/), [ReactFiberHooks](https://stackoverflow.com/a/53980190/7971276)), or they are too high level (["it's just arrays"](https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e), closures, call order).

Here is an answer for me[^i-am-not-ai]:
1. A JSX tag is transformed into a function call, passing in the tag name as a string, properties as an object, and its children as expressions (recursively transformed as well).
2. The children of a JSX element are transformed into positional function arguments[^params-vs-args] that have a stable order. This is stable even if they are conditionally rendered, since the conditional expression occupies the argument slot. List expressions [need keys](https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e) because JSX transforms them into a single argument.
3. Hooks use order within the JSX tree to index into which component state to load.
4. Hooks within the same component are distinguished by call order in that component. This is possible because of the [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks).

[^i-am-not-ai]: I like lists and bullets and I am not AI. Tautology.town is written by hand! I like em-dashes too, but that battle has been lost.

[^params-vs-args]: "Parameter" and "argument" can be conflated, but strictly speaking a parameter is the name in the function definition and argument is the actual value supplied. That distinction is important here.






# References

- [Build your own React (Rodrigo Pombo)](https://pomb.us/build-your-own-react/): this was helpful in understanding how JSX transforms into Javascript, which is the key that a lot of other resources missed or assumed. Very detailed!
- [Getting Closure on React Hooks (swyx)](https://www.swyx.io/hooks): this explains closure for hooks and derives the rules of hooks.
- [Making Sense of React Hooks (Dan Abramov)](https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889#:~:text=We%20keep%20a,calling%20your%20component.): introduces some benefits of hooks and talks about the implementation at a high level
  - Also, the linked [pseudocode from @jamiebuilds](https://gist.github.com/gaearon/62866046e396f4de9b4827eae861ff19)
- [Introducing JSX (legacy React docs)](https://legacy.reactjs.org/docs/introducing-jsx.html): outdated (`_jsx` is now called instead of `React.createElement`) but useful context
- [StackOverflow answer from Knight Industries](https://stackoverflow.com/a/71731023/7971276): provided some intuition, not as useful on its own
- Asking questions to [Claude](https://claude.ai/) was helpful in honing my understanding, especially for the conditional rendering question with JSX, which I verified with [Babel](https://babeljs.io/repl).
- [Hooks FAQ: How does React associate hook calls with components (legacy React docs)](https://legacy.reactjs.org/docs/hooks-faq.html#how-does-react-associate-hook-calls-with-components): the is the former "official" answer, but it's very high level.
