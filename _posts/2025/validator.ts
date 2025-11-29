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