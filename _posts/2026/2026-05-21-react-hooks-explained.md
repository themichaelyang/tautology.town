---
layout: post
title: "How React hooks associate functions with state"
---

How do React hooks know which component instance is being called, without requiring a stable identifier? This is the dark magic of React.

There are many high quality answers online. For me, they either focus too much on React internals ([Fibers](https://stackoverflow.com/a/53730788/7971276), [render cycle](https://eliav2.github.io/how-react-hooks-work/), [ReactFiberHooks](https://stackoverflow.com/a/53980190/7971276)), or they are too high level (["it's just arrays"](https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e), closures, call order). 

Here is my answer, written for me (and by me): 

*React uses the location of a component in the virtual DOM tree to retrieve the component instance's state. Within each instance, the order that hooks are called indexes the individual hook state, possible because of the [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks).*

This is alluded to in the [React docs](https://react.dev/learn/preserving-and-resetting-state):

> React keeps track of which state belongs to which component based on their place in the UI tree.  
> ...  
> When you give a component state, you might think the state “lives” inside the component. But the state is actually held inside React. React associates each piece of state it’s holding with the correct component by where that component sits in the render tree.

We can think of this as keeping a second "context" tree that mirrors the structure of the UI tree. On a render (updating the UI tree), it walks through both the UI tree and context tree in the same position. Before each functional component is called, the hook context is pulled from the corresponding node in the context tree to be used implicitly by the hook calls.

This is how you might implement a bare bones `useState`:

```javascript
let context = {hookState: [], hookIndex: 0} // hook context

// 0. on first render, contextNode tree copies vnode (virtual DOM) tree structure
// visit() will be called per component instance/node when rendering 
function visit(vnode, contextNode) {
  context = contextNode // 1. set up the context
  context.hookIndex = 0 // reset for the current component
  renderStuff(vnode) // 2. calls the functional component
  vnode.children.forEach((child, i) => visit(vnode, contextNode.children[i]))
}

// 3. when the functional component is called the correct context is set
function useState(initial) {
  // within a component, keep track of which hook index is being called
  const index = context.hookIndex
  context.hookIndex += 1

  // 4. if there is no prior state, initialize it!
  if (index >= context.hookState.length) {
    context.hookState[index] = initial
  }

  return [
    () => context.hookState[index], // getter
    (value) => { // setter
      context.hookState[index] = value
      queueRender()
    }
  ]
}
```

## Conditionally rendered elements

How does this work for conditionally rendered elements? If an element is not rendered, then wouldn't it lose its place in the rendering tree, messing up the rest of the tree?

My own confusion around this stemmed from the convenient representation of JSX.

JSX tags are transformed into function calls like this ([try for yourself](https://babeljs.io/repl)):

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
```jsx
<Parent name="example">
  {showA && <A/>}
  <B/>
  <C/>
</Parent>
```

```javascript
_jsxs(Parent, {
  name: "example",
  children: [
    showA && _jsx(A, {}), 
    _jsx(B, {}),
    _jsx(C, {})
  ]
});
```
</div>

Where `_jsx` and `_jsxs` are implemented by React or your framework of choice.

Each of the children occupy their own place in an Array passed into the parent `_jsxs` call. In fact, the entire conditional expression `{showA && <A/>}` takes its own place in the array!

So the constructed "UI tree" preserves child indexes, even with a conditional render. 

Naturally, this does not apply to components that return divergent JSX branches. In those cases, React should notice the tree has changed (by node type) and reinitialize local state.

## Keys and lists of elements

This also explains why lists of elements need a `key`. The entire array producing expression occupies an array index, so it becomes ambiguous which component is which since they share an index.

<div class="side-by-side" markdown="1">
```jsx
<Parent name="example">
  {arr.map(item => <A/>)}
  <B/>
  <C/>
</Parent>
```

```javascript
_jsxs(Parent, {
  name: "example",
  children: [
    arr.map(item => _jsx(A, {})), 
    _jsx(B, {}),
    _jsx(C, {})
  ]
});
```
</div>

## The long answer[^i-am-not-ai]

1. Each JSX tag is transformed into a `_jsx` function call, passing in the tag name as a string, properties as an object. A tag's child tags are passed as an array of expressions.
2. React executes this function call and constructs a "virtual DOM" tree describing the intended DOM structure. React knows how to efficiently update the real DOM from the virtual DOM.
3. React stores local state for each component in a tree mirroring the virtual DOM. When state is updated, uses the position within the tree to load the right state for hooks.
5. Hooks within the same component are distinguished by call order in that component. This is possible because of the [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
6. This works with a conditionally rendered component (i.e. `{hasAnnouncement && <Annoucement>}) because the entire conditional expression is included in the children array of its parent, so the index of the component is stable. 
7. Lists of components need keys because the entire list expression occupies a single index in the children array of its parent, so they need their own stable identifier.

# Sources

- [Build your own React (Rodrigo Pombo)](https://pomb.us/build-your-own-react/): this was helpful in understanding how JSX transforms into Javascript, which is the key that a lot of other resources missed or assumed. Very detailed!
- [Getting Closure on React Hooks (swyx)](https://www.swyx.io/hooks): this explains closure for hooks and derives the rules of hooks.
- [Making Sense of React Hooks (Dan Abramov)](https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889#:~:text=We%20keep%20a,calling%20your%20component.): introduces some benefits of hooks and talks about the implementation at a high level
  - Also, the linked [pseudocode from @jamiebuilds](https://gist.github.com/gaearon/62866046e396f4de9b4827eae861ff19)
- [Introducing JSX (legacy React docs)](https://legacy.reactjs.org/docs/introducing-jsx.html): outdated (`_jsx` is now called instead of `React.createElement`) but useful context
- [StackOverflow answer from Knight Industries](https://stackoverflow.com/a/71731023/7971276): provided some intuition, not as useful on its own
- Asking questions to [Claude](https://claude.ai/) was helpful in honing my understanding, especially for the conditional rendering question with JSX, which I verified with [Babel](https://babeljs.io/repl).
- [Hooks FAQ: How does React associate hook calls with components (legacy React docs)](https://legacy.reactjs.org/docs/hooks-faq.html#how-does-react-associate-hook-calls-with-components): this is the former "official" answer, but it's very high level.
- [Preserving and Resetting State (React docs)](https://react.dev/learn/preserving-and-resetting-state): mostly helpful, but a bit handwavey around "UI tree". For example, conditional rendering example hides the second, not first, `Counter()`.
- [Reconciliation (legacy React docs)](https://legacy.reactjs.org/docs/reconciliation.html)

---- 

[^i-am-not-ai]: I like lists and bullets and I am not AI. Tautology.town is written by hand! I like em-dashes too, but that battle has been lost.
