---
layout: post
title: "How to typecheck schemas in Typescript"
---

Typescript has no runtime for types, so something that comes up frequently is getting a schema defined 
in runtime code to produce useful static types at compile time.

Many libraries manage to do this, although they each look slightly different.

[Zod](https://zod.dev/) is a classic example for validating objects, using schemas with Zod-defined types: 

```typescript
import * as z from "zod"
 
const User = z.object({ 
  email: z.email(),
  age: z.number().optional(),
})

type UserType = z.infer<typeof User>
// type UserType = {
//   email: string,
//   age: number | undefined,
// }

let result = User.safeParse({ email: 'example@example.com' })

if (!result.success) {
  result.error   // ZodError instance
} else {
  result.data    // UserType
}
```

[Mongoose](https://mongoosejs.com/docs/typescript/schemas.html) uses [primitive type wrapper classes](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Data_structures#primitive_values) to declare types for its MongoDB database schemas:

```typescript
import { Schema, model } from 'mongoose'

const schema = new Schema({
  email: { type: String, required: true },
  age: { type: Number, required: false },
})
const UserModel = model('User', schema)

const user = new UserModel({ 
  email: 'example@example.com',
})
// new UserModel(...) expects type = {
//   email: string,
//   age: number | undefined | null
// }
```

These are just two examples, and there are many others, like [Arktype](https://arktype.io/). But you can already imagine many more use cases like API definitions, binary codec definitions, automatic [RPCs](https://en.wikipedia.org/wiki/Remote_procedure_call), etc.

Perhaps you'd like to implement your own. Doing this is extraordinarily useful and convenient, but involves a bit of advanced Typescript to implement.

Luckily for you, I've learned how to do this. To demonstrate, let's make a simple validation library similar to our examples. I'll assume you have working knowledge of [basic Typescript](https://www.typescriptlang.org/docs/handbook/typescript-in-5-minutes.html), and maybe even seen [a generic or two](https://www.typescriptlang.org/docs/handbook/2/generics.html).

## Making of a typed validator

Let's start by seeing how it will be used:

```typescript
let userValidator = new Validator({
  email: { required: true, kind: new ValidEmail() },
  age: { required: false, kind: new ValidInteger() }
})

// userValidator.validate(...) returns either 
// { email: string, age: number | null } type or Error[]
let validated = userValidator.validate({
  email: 'example@example.com',
  age: 100
})

if (isValid(validated)) {
  // { email: string, age: number | null } type
  let user = validated 
  console.log("Valid user!")
} else {
  // Error[] type
  let errors = validated
  throw errors[0]
}
```

As you can see, the validator returns either the typed validated object or returns a list of `Error`s. 

If you want preview the finished code, [⏩ click here skip ahead to the end](#all-together-now).

## Validator literal type with `const` and generics

Let's start with a type for the object literal defining a single validator field with `required` and `kind` properties. 

```typescript
type ValidatorFieldDef = {
  required: boolean,
  kind: any
}
```

Then a type for the entire validator literal: 

```typescript
type ValidatorLiteral = {
  [key: string]: ValidatorFieldDef
}
```

`ValidatorLiteral` uses an [index signature](https://www.typescriptlang.org/docs/handbook/2/objects.html#index-signatures), but you could use also a `Record` [type](https://www.typescriptlang.org/docs/handbook/utility-types.html#recordkeys-type).

Finally, a `Validator` class that is instantiated by the validator literal:

```typescript
class Validator<const T extends ValidatorLiteral> {
  literal: T

  constructor(defn: T) {
    this.literal = defn
  }
}
```

We declare a generic type parameter `T` with the `const` modifier on `Validator`.

Generics bind a type to the type variable (e.g. `T`) for a specific class instance or function call and are scoped to the class or function body they are declared in. They can be explicitly assigned, or use the first inferred type if not specified.

If we did `let bar = new Validator(foo)`, `T` would be inferred to be `typeof foo`, and all other occurrences of `T` within `bar` are checked as if `type T = typeof foo`. 

Typescript's [handbook section on generics](https://www.typescriptlang.org/docs/handbook/2/generics.html#generic-types) is very good (go read that).

The `const` modifier on the generic `T` means any object literal (taking on type `T`) passed directly to the constructor should have its values treated as literals and not type widen literals like `true` or `false` to `boolean`. Sort of like how Typescript already preserves parameter names in object literals (e.g. `"email"` and `"name"`). Without the modifier, `as const` would be needed on the parameter (it's still needed if the parameter is passed through an intermediate variable instead of directly into the constructor). `const` also marks the type's properties as `readonly`.

The `const` and `as const` keywords are described [here](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html#const-type-parameters) and [here](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-4.html#const-assertions). Unfortunately, some features are only described in the release notes and PRs.

We can verify that it's typed correctly:

```typescript
let example = new Validator({
  email: {
    required: true,
    kind: null // TODO
  },
})
// see that const preserves the `true` literal!
type ExampleLiteralType = typeof example.literal 
```

## Field validation interface

Next, we define a `ValidatorFieldKind` interface with a generic for the validated type, and a `validate` method that returns either the validated type or an error. We update `kind` to use this definition. `ValidatorFieldDef` shares this by declaring its own generic variable and passing it through. Lifting the variable in this way will help us extract the type from `ValidatorFieldDef` later. 

```typescript
interface ValidatorFieldKind<D> { // added
  validate(value: any): D | Error
}

type ValidatorFieldDef<D> = { // added <D>
  required: boolean,
  kind: ValidatorFieldKind<D> // updated to ValidatorFieldKind<D>
}

type ValidatorLiteral = {
  [key: string]: ValidatorFieldDef<any> // updated to <any>
}
```

Now we can define the field validators from our example like `ValidEmail` and `ValidInteger` by implementing this interface:

```typescript
class ValidInteger implements ValidatorFieldKind<number> {
  validate(value: any) {
    if (typeof value === 'number' && Number.isInteger(value)) {
      return value
    } else {
      return new Error(`${value} is not an integer`)
    }
  }
}

class ValidEmail implements ValidatorFieldKind<string> {
  validate(value: any) {
    if (typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
      return value
    } else {
      return new Error(`${value} is not an email`)
    }
  }
}
```

With the field validators defined, we can add an untyped (for now) `validate` method. This works, but the object type is `Record<any, any>` instead of a proper type derived from the schema.

```typescript
class Validator<const T extends ValidatorLiteral> {
  literal: T

  constructor(defn: T) {
    this.literal = defn
  }

  // TODO: infer correct object type
  validate(obj: Record<any, any>): Record<any, any> | Error[] {
    let errors: Error[] = []
    let copy: Record<any, any> = {}

    for (let key of Object.keys(this.literal)) {
      let field = this.literal[key]
      if (field.required && !(key in obj)) {
        errors.push(new Error(`required key "${key}" missing`))
      }

      if (key in obj) {
        let coerced = field.kind.validate(obj[key])
        if (coerced instanceof Error) {
          errors.push(new Error(`key ${key} has error: ${coerced.message}`))
        } else {
          copy[key] = coerced
        }
      } else {
        copy[key] = null
      }
    }

    let obj_keys = new Set(Object.keys(obj))
    let schema_keys = new Set(Object.keys(this.literal))
    // add this magic comment to the top of the file to use `Set#difference`: 
    // `/// <reference lib="esnext" />`
    let extra_keys = obj_keys.difference(schema_keys)
    if (extra_keys.size > 0) {
      errors.push(new Error(`extra keys: ${extra_keys.values().toArray()}`))
    }

    if (errors.length > 0) {
      return errors
    } else {
      return copy
    }
  }
}
```

If we update our example, we can verify again that it typechecks:

```typescript
let example = new Validator({
  email: { required: true, kind: new ValidEmail() },
  age: { required: false, kind: new ValidInteger() }
})
```

Now we have the types for the schema definition, we need to extract the type of the object we expect it to output.

First, we convert `required` to a generic type so we can extract the true or false literal later using an `infer` keyword in a [conditional type](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html#inferring-within-conditional-types).

```typescript
// updated to <R extends boolean, D>
type ValidatorFieldDef<R extends boolean, D> = {
  required: R, // updated to R
  kind: ValidatorFieldKind<D>
}

type ValidatorLiteral = {
  [key: string]: ValidatorFieldDef<any, any> // updated to <any, any>
}
```

## Validated object type

Finally, the magic. We use a [*mapped type*](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html) with a [conditional](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html#further-exploration).

```typescript
type ValidatorLiteralToObject<C> = {
  -readonly [K in keyof C]: C[K] extends ValidatorFieldDef<infer R, infer D> ? 
    (R extends true ? D : D | null)
    : never
}
```

We can make `ValidatorLiteralToObject<T>` the return type of `Validator#validate()` and cast `copy` at the end.

We need to take care to check that types are correct in that method, which is one weakness of this approach (i.e. being consistent with `undefined`, `null`, and omitted properties).

With the output type derived from the schema, we've now completed our typed validation library!

```typescript
class Validator<const T extends ValidatorLiteral> {
  literal: T

  constructor(defn: T) {
    this.literal = defn
  }

  // Updated with ValidatorLiteralToObject<T> | Error[]
  validate(obj: Record<any, any>): ValidatorLiteralToObject<T> | Error[] {
    let errors: Error[] = []
    let copy: Record<any, any> = {} 

    for (let key of Object.keys(this.literal)) {
      let field = this.literal[key]
      if (field.required && !(key in obj)) {
        errors.push(new Error(`required key "${key}" missing`))
      }

      if (key in obj) {
        let coerced = field.kind.validate(obj[key])
        if (coerced instanceof Error) {
          errors.push(new Error(`key ${key} has error: ${coerced.message}`))
        } else {
          copy[key] = coerced
        }
      } else {
        copy[key] = null
      }
    }

    let obj_keys = new Set(Object.keys(obj))
    let schema_keys = new Set(Object.keys(this.literal))
    // add this magic comment to the top of the file to use `Set#difference`: 
    // `/// <reference lib="esnext" />`
    let extra_keys = obj_keys.difference(schema_keys)
    if (extra_keys.size > 0) {
      errors.push(new Error(`extra keys: ${extra_keys.values().toArray()}`))
    }

    if (errors.length > 0) {
      return errors
    } else {
      // Updated with ValidatorLiteralToObject<T>
      return copy as ValidatorLiteralToObject<T>
    }
  }
}
```

You can think of `ValidatorLiteralToObject<C>` as a function that transforms types, using a generic type variable `C` as a parameter. To use this, we need to explicitly pass in a type to the generic.

```typescript
let example = new Validator({
  email: { required: true, kind: new ValidEmail() },
  age: { required: false, kind: new ValidInteger() }
})

type ExampleObjectType = ValidatorLiteralToObject<typeof example.literal>
// type ExampleObjectType = {
//   email: string,
//   age: number | null
// }
```

Let's break down what's happening in `ValidatorLiteralToObject`.

### Mapped types

First, we use a mapped type. For `ValidatorLiteralToObject<typeof example.literal>`, `C` is `typeof example.literal`,
`keyof C` is `"email" | "age"`. `K in keyof C` iterates each key in the union, so `K` is `email`, then `age`.

As a basic example of mapped types, the following type produces the same type as `C` by producing a new type that has the same key-value pairs:

```typescript
let example = new Validator({
  email: { required: true, kind: new ValidEmail() },
  age: { required: false, kind: new ValidInteger() }
})

type NoChanges<C> = {
  [K in keyof C]: C[K]
}

type ExampleNoChanges = NoChanges<typeof example.literal>
// type ExampleNoChanges = {
//   readonly email: { 
//     readonly required: true, 
//     readonly kind: ValidEmail 
//   },
//   readonly age: { 
//     readonly required: false, 
//     readonly kind: ValidInteger
//   }
// }
```

The `-readonly` [mapping modifier](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html#mapping-modifiers) removes (`-`) the `readonly` attribute from the remapped keys of `C`, making the new type mutable. As a consequence of using `const T` for `Validator`, the type `T` for `literal` will have `readonly` properties.

```typescript
let example = new Validator({
  email: { required: true, kind: new ValidEmail() },
  age: { required: false, kind: new ValidInteger() }
})

type MakeMutable<C> = {
  -readonly [K in keyof C]: C[K]
}
// only removes `readonly` for `K in keyof C` (one layer)
type ExampleMutable = MakeMutable<typeof example.literal>
// type ExampleMutable = {
//   email: { 
//     readonly required: true, 
//     readonly kind: ValidEmail 
//   },
//   age: { 
//     readonly required: false, 
//     readonly kind: ValidInteger
//   }
// }

type MakeNestedMutable<C> = {
  -readonly [K in keyof C]: {
    -readonly [K2 in keyof C[K]]: C[K][K2]
  }
}
type ExampleNestedMutable = MakeNestedMutable<typeof example.literal>
// type ExampleMutable = {
//   email: { 
//     required: true, 
//     kind: ValidEmail 
//   },
//   age: { 
//     required: false, 
//     kind: ValidInteger
//   }
// }
```

### Conditional types and the `infer` keyword

Next, we add [conditional types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html). `ValidatorLiteralToObject` makes use of two conditionals, one nested in the other.

Let's look at a basic conditional first. These look like Javascript ternary operators, but use `extends` to check if the generic type
matches another type condition to determine the final type.

```typescript
// CheckType, TypeIfIsCheckType, TypeIfNotCheckType defined before or
// or replaced with inline types
type Conditional<A> = A extends CheckType ? TypeIfIsCheckType : TypeIfNotCheckType
```

Now we can make the innermost conditional, which is is type `K` if `R` is type `true` or `K | null` if not.

```typescript
type IfTrue<R, K> = R extends true ? K : K | null 

// `as const` needed to prevent `true` from becoming `boolean`
let fieldExampleTrue = {
  required: true,
} as const

// `as const` needed to prevent `false` from becoming `boolean`
let fieldExampleFalse = {
  required: false,
} as const

type FieldExampleTrueIfTrue = IfTrue<typeof fieldExampleTrue.required, number>
// type FieldExampleTrueIfTrue = number

type FieldExampleFalseIfTrue = IfTrue<typeof fieldExampleFalse.required, number>
// type FieldExampleFalseIfTrue = number | null
```

Conditional types can include the `infer` keyword. It's like pattern matching for types. If a conditional type is a type with generics, we can "unwrap" those inner generics by binding the matched inner generics to new type variables that can be used in the matching case.

This may be clearer in the example with `UnwrapInnerType`, which corresponds to the outer conditional.

```typescript
// ValidatorFieldKind, ValidatorFieldDef and ValidInteger repeated for clarity
interface ValidatorFieldKind<D> {
  validate(value: any): D | Error
}

type ValidatorFieldDef<D> = {
  required: boolean,
  kind: ValidatorFieldKind<D>
}

class ValidInteger implements ValidatorFieldKind<number> {
  validate(value: any) {
    // ... (not important, see above)
  }
}

// the new type of interest!
type UnwrapInnerType<T> = T extends ValidatorFieldDef<infer R, infer D> ? 
  [R, D] : never

let fieldExample = {
  required: true,
  kind: new ValidInteger()
} as const

type UnwrappedFieldExampleType = UnwrapInnerType<typeof fieldExample>
// type UnwrappedFieldExampleType = [true, number]
```

`never` is a special type that lets Typescript know to always fail the type check, so `UnwrapInnerType` requires a `ValidatorFieldDef`.

Now you see why we needed to add a generic to `ValidatorFieldDef` that matched `ValidatorFieldKind`, so Typescript can `infer` the return type of `.kind.validate()`.

Putting it all together: `ValidatorLiteralToObject` is mapping each key `K` of the validator literal `C` to a nested conditional type that `infer`s the return value of `C[K].kind.validate()` as `D` and adds `| null` if `required` is `false`.

## Type predicates for narrowing

Let's also add [type predicates](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#using-type-predicates) to preserve our typing but narrow it if an object passes or fails validation.

```typescript
function hasErrors<T>(obj: T | Error[]): obj is Error[] {
  return Array.isArray(obj) && obj.every(e => e instanceof Error)
}

function isValid<T>(obj: T | Error[]): obj is T {
  return !hasErrors(obj)
}
```

## All together now

Here's the final code, all in one place.

As an exercise to the reader, how would we change this to allow nested validators? (hint: `validate()`)

Hope you found this helpful. I myself learned a lot about Typescript writing this!

Did you skip ahead? [⏮️ Click here](#making-of-a-typed-validator) to go back to the start.

```typescript
/// <reference lib="esnext" />

interface ValidatorFieldKind<D> {
  validate(value: any): D | Error
}

type ValidatorFieldDef<R extends boolean, D> = {
  required: R,
  kind: ValidatorFieldKind<D>
}

type ValidatorLiteral = {
  [key: string]: ValidatorFieldDef<any, any>
}

class ValidInteger implements ValidatorFieldKind<number> {
  validate(value: any) {
    if (typeof value === 'number' && Number.isInteger(value)) {
      return value
    } else {
      return new Error(`${value} is not an integer`)
    }
  }
}

class ValidEmail implements ValidatorFieldKind<string> {
  validate(value: any) {
    if (typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
      return value
    } else {
      return new Error(`${value} is not an email`)
    }
  }
}

type ValidatorLiteralToObject<C> = {
  -readonly [K in keyof C]: C[K] extends ValidatorFieldDef<infer R, infer D> ? 
    (R extends true ? D : D | null)
    : never
}

class Validator<const T extends ValidatorLiteral> {
  literal: T

  constructor(defn: T) {
    this.literal = defn
  }

  validate(obj: Record<any, any>): ValidatorLiteralToObject<T> | Error[] {
    let errors: Error[] = []
    let copy: Record<any, any> = {} 

    for (let key of Object.keys(this.literal)) {
      let field = this.literal[key]
      if (field.required && !(key in obj)) {
        errors.push(new Error(`required key "${key}" missing`))
      }

      if (key in obj) {
        let coerced = field.kind.validate(obj[key])
        if (coerced instanceof Error) {
          errors.push(new Error(`key ${key} has error: ${coerced.message}`))
        } else {
          copy[key] = coerced
        }
      } else {
        copy[key] = null
      }
    }

    let obj_keys = new Set(Object.keys(obj))
    let schema_keys = new Set(Object.keys(this.literal))

    let extra_keys = obj_keys.difference(schema_keys)
    if (extra_keys.size > 0) {
      errors.push(new Error(`extra keys: ${extra_keys.values().toArray()}`))
    }

    if (errors.length > 0) {
      return errors
    } else {
      return copy as ValidatorLiteralToObject<T>
    }
  }
}

function hasErrors<T>(obj: T | Error[]): obj is Error[] {
  return Array.isArray(obj) && obj.every(e => e instanceof Error)
}

function isValid<T>(obj: T | Error[]): obj is T {
  return !hasErrors(obj)
}

let userValidator = new Validator({
  email: { required: true, kind: new ValidEmail() },
  age: { required: false, kind: new ValidInteger() }
})

// userValidator.validate(...) returns either 
// { email: string, age: number | null } type or Error[]
let validated = userValidator.validate({
  email: 'example@example.com',
  age: 100
})

if (isValid(validated)) {
  // { email: string, age: number | null } type
  let user = validated 
  console.log("Valid user!")
} else {
  // Error[] type
  let errors = validated
  throw errors[0]
}

// A utility type from ChatGPT to expand and see the fully resolved type:
type Expand<T> = T extends infer O ? { [K in keyof O]: O[K] } : never;

type ValidUser = Expand<ReturnType<typeof userValidator.validate>>
// type ValidUser = Error[] | { email: string, age: number | null }
```

## And the illustrative examples

For your copying pleasure.

```typescript
let example = new Validator({
  email: { required: true, kind: new ValidEmail() },
  age: { required: false, kind: new ValidInteger() }
})

type NoChanges<C> = {
  [K in keyof C]: C[K]
}
type ExampleNoChanges = NoChanges<typeof example.literal>
// type ExampleNoChanges = {
//   readonly email: { 
//     readonly required: true, 
//     readonly kind: ValidEmail 
//   },
//   readonly age: { 
//     readonly required: false, 
//     readonly kind: ValidInteger
//   }
// }

type MakeMutable<C> = {
  -readonly [K in keyof C]: C[K]
}
// only removes `readonly` for `K in keyof C` (one layer)
type ExampleMutable = MakeMutable<typeof example.literal>
// type ExampleMutable = {
//   email: { 
//     readonly required: true, 
//     readonly kind: ValidEmail 
//   },
//   age: { 
//     readonly required: false, 
//     readonly kind: ValidInteger
//   }
// }

type MakeNestedMutable<C> = {
  -readonly [K in keyof C]: {
    -readonly [K2 in keyof C[K]]: C[K][K2]
  }
}
type ExampleNestedMutable = MakeNestedMutable<typeof example.literal>
// type ExampleMutable = {
//   email: { 
//     required: true, 
//     kind: ValidEmail 
//   },
//   age: { 
//     required: false, 
//     kind: ValidInteger
//   }
// }

type IfTrue<R, K> = R extends true ? K : K | null 

// `as const` needed to prevent `true` from becoming `boolean`
let fieldExampleTrue = {
  required: true,
} as const

// `as const` needed to prevent `false` from becoming `boolean`
let fieldExampleFalse = {
  required: false,
} as const

type FieldExampleTrueIfTrue = IfTrue<typeof fieldExampleTrue.required, number>
// type FieldExampleTrueIfTrue = number

type FieldExampleFalseIfTrue = IfTrue<typeof fieldExampleFalse.required, number>
// type FieldExampleFalseIfTrue = number | null

type UnwrapInnerType<T> = T extends ValidatorFieldDef<infer R, infer D> ? 
  [R, D] : never

let fieldExample = {
  required: true,
  kind: new ValidInteger()
} as const

type UnwrappedFieldExampleType = UnwrapInnerType<typeof fieldExample>
// type UnwrappedFieldExampleType = [true, number]
```

Cheers!
