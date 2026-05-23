---
layout: post
title: "How React associate functions with state"
---

How do React hooks know which component instance is being called, without requiring a stable identifier?

There are many high quality answers online. For me, they either focus too much on React internals ([Fibers](https://stackoverflow.com/a/53730788/7971276), [render cycle](https://eliav2.github.io/how-react-hooks-work/), [ReactFiberHooks](https://stackoverflow.com/a/53980190/7971276)), or they are too high level (["it's just arrays"](https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e), closures, call order). 

Here is my answer, written for me (and by me): 

*React uses the location of a component in the virtual DOM tree to retrieve the component instance's state. Within each instance, the call order of hooks indexes the individual hook state [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks).*

This is alluded to in the [React docs](https://react.dev/learn/preserving-and-resetting-state):

> React keeps track of which state belongs to which component based on their place in the UI tree.  
> ...  
> When you give a component state, you might think the state “lives” inside the component. But the state is actually held inside React. React associates each piece of state it’s holding with the correct component by where that component sits in the render tree.

## Conditionally rendered elements

Something that initially escaped me was how this works for conditionally rendered elements. If the element is not rendered, then wouldn't it "lose its place" in the rendering tree?







Here is my long answer:

1. Each JSX tag is transformed into a `_jsx` function call, passing in the tag name as a string, properties as an object. A tag's child tags are passed as an array of expressions.
2. React executes this function call and constructs a "virtual DOM" tree describing the intended DOM structure. React knows how to efficiently update the real DOM from the virtual DOM.
3. React stores local state for each component in a  tree mirroring the virtual DOM. When state is updated, uses the position within the tree to load the right state for hooks.
5. Hooks within the same component are distinguished by call order in that component. This is possible because of the [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
6. This works with a conditionally rendered component (i.e. `{hasAnnouncement && <Annoucement>}) because the entire conditional expression is included in the children array of its parent, so the index of the component is stable. 
7. Lists of components need keys because the entire list expression occupies a single index in the children array of its parent, so they need their own stable identifier.

I found this fact very surprising, because of conditionally rendered elements. 

In the chapter "Preserving and Resetting State" it gives the example of two adjacent counters, and a toggle to conditionally render the second counter.

```jsx
<Counter />
{showB && <Counter />}
```
<div id="counter-demo"></div>

<script type="text/babel" data-type="module">
  import { useState } from 'https://esm.sh/react@18';
  import { createRoot } from 'https://esm.sh/react-dom@18/client';

  function Counter() {
    const [n, setN] = useState(0);
    return <button onClick={() => setN(n + 1)}>count: {n}</button>;
  }

  createRoot(document.getElementById('counter-demo')).render(<Counter/>);
</script>

If you update the second counter, then toggle it, it resets the second counter.

> React preserves a component’s state for as long as it’s being rendered at its position in the UI tree. If it gets removed, or a different component gets rendered at the same position, React discards its state.

And also:

> Remember that **it’s the position in the UI tree—not in the JSX markup—that matters to React!**

Later, it shows an example where two separate JSX markups that produce the same UI tree preserve the state.

What if we hid the first counter? As you may expect, the state of the second counter is preserved.

```jsx
{showA && <Counter />}
<Counter />
```

Given the "UI tree", you may be surprised! Why doesn't the second `Counter` "take the place" of the first one, when the first counter is not rendered?

My confusion around this stems, in part, from the convenient representation of JSX.

[^i-am-not-ai]: I like lists and bullets and I am not AI. Tautology.town is written by hand! I like em-dashes too, but that battle has been lost.



<!--
1. A JSX tag is transformed into a function call, passing in the tag name as a string, properties as an object, and its children as an array of expressions.
2. The children of a JSX element have a stable order in the transformed Javascript, even if they are conditionally rendered. This is because the conditional expression occupies a position in the child array. This also means list expressions [need keys](https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e) because the JSX is transformed into a single expression.
3. React uses order within the JSX tree to index into which component state to load for hooks.
4. Hooks within the same component are distinguished by call order in that component. This is possible because of the [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks).
5. If a JSX element is conditionally included (as opposed to conditionally rendered), the new JSX tree node is compared to the previous tree based on type.

# JSX transforms

Perhaps the most important yet overlooked contribution of React is JSX by allowing components to look like markup.-->

```

```

```
function A() {}
function B() {}
function C() {}

function A1() {}
function A2() {}
function A3() {}

function Parent() {
  return <div>
    <A>
      <A1/>
      <A2/>
      <A3/>
    </A>
    <B/>
    <C/>
  </div>
}
```

# Sources

- [Build your own React (Rodrigo Pombo)](https://pomb.us/build-your-own-react/): this was helpful in understanding how JSX transforms into Javascript, which is the key that a lot of other resources missed or assumed. Very detailed!
- [Getting Closure on React Hooks (swyx)](https://www.swyx.io/hooks): this explains closure for hooks and derives the rules of hooks.
- [Making Sense of React Hooks (Dan Abramov)](https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889#:~:text=We%20keep%20a,calling%20your%20component.): introduces some benefits of hooks and talks about the implementation at a high level
  - Also, the linked [pseudocode from @jamiebuilds](https://gist.github.com/gaearon/62866046e396f4de9b4827eae861ff19)
- [Introducing JSX (legacy React docs)](https://legacy.reactjs.org/docs/introducing-jsx.html): outdated (`_jsx` is now called instead of `React.createElement`) but useful context
- [StackOverflow answer from Knight Industries](https://stackoverflow.com/a/71731023/7971276): provided some intuition, not as useful on its own
- Asking questions to [Claude](https://claude.ai/) was helpful in honing my understanding, especially for the conditional rendering question with JSX, which I verified with [Babel](https://babeljs.io/repl).
- [Hooks FAQ: How does React associate hook calls with components (legacy React docs)](https://legacy.reactjs.org/docs/hooks-faq.html#how-does-react-associate-hook-calls-with-components): this is the former "official" answer, but it's very high level.
- [Reconciliation (legacy React docs)](https://legacy.reactjs.org/docs/reconciliation.html)
- [Preserving and Resetting State (React docs)](https://react.dev/learn/preserving-and-resetting-state)
