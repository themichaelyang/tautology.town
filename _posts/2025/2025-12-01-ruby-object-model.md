---
layout: post
title: "Ruby's object model: eigenclasses, metaclasses, and more"
---

*Or: a Class class class masterclass*

One way or another, a famous question will cross every Rubyist's mind, probably many times: *what's an eigenclass?*

In the Ruby docs, there's a tremendous diagram under [the page for `class Class`](https://docs.ruby-lang.org/en/3.4/Class.html#method-i-new:~:text=In%20the%20diagram%20that%20follows%2C%20the%20vertical%20arrows%20represent%20inheritance%2C%20and%20the%20parentheses%20metaclasses.) that made me think of this again:

> Classes, modules, and objects are interrelated. In the diagram that follows, the vertical arrows represent inheritance, and the parentheses metaclasses. All metaclasses are instances of the class ‘Class’.
>
> ```
                         +---------+             +-...
                         |         |             |
         BasicObject-----|-->(BasicObject)-------|-...
             ^           |         ^             |
             |           |         |             |
          Object---------|----->(Object)---------|-...
             ^           |         ^             |
             |           |         |             |
             +-------+   |         +--------+    |
             |       |   |         |        |    |
             |    Module-|---------|--->(Module)-|-...
             |       ^   |         |        ^    |
             |       |   |         |        |    |
             |     Class-|---------|---->(Class)-|-...
             |       ^   |         |        ^    |
             |       +---+         |        +----+
             |                     |
obj--->OtherClass---------->(OtherClass)-----------...
```

I thought I more or less understood Ruby classes, eigenclasses, and what have you, until I came across this. I don't know about you, but this made very little sense to me. Is a metaclass the same as an eigenclass?

This Question is famous and Frequently Asked enough that Ruby has [an official FAQ answer](https://www.ruby-lang.org/en/documentation/faq/8/#:~:text=What%20is%20a%20singleton%20class%3F) (also: why is this in an FAQ instead of [having better docs](https://gds.blog.gov.uk/2013/07/25/faqs-why-we-dont-have-them/)?).

> A singleton class is an anonymous class that is created by subclassing the class associated with a particular object. Singleton classes are another way of extending the functionality associated with just one object.

Better. By the way, singleton class is another word for eigenclass. Does the diagram make any more sense?

After an exciting afternoon, I think I have the definitive answer. Let me now try to answer the question, by way of answering everything.

### Objects have a class

Everything in Ruby is an object.

Every object in Ruby has a class. 

```
object -- has a --> a class 
```

Even "primitive" types are objects.

Every object in Ruby has a class.

The class is available in the `class` method, which returns the class of an object.

```ruby
irb(main):001> "hello world".class
=> String
irb(main):002> 123.class
=> Integer
```

### Classes have ancestors

We can define our own classes with the `class` keyword. Then make an instance of that class with `new()`.

```ruby
irb(main):001* class A
irb(main):002> end
=> nil
irb(main):003> a = A.new
=> #<A:0x0000000132451b58>
irb(main):004> a.class
=> A
```

A class has ancestors which it inherits from. On the class itself there is a `ancestors` method, which returns the order of classes that it inherits from. 

```
              (... rest of ancestors)
                      |  
                    a class
                      ^
                      |
                inherits from  
                      |
object -- has a --> a class 
```

```ruby
irb(main):001* class A
irb(main):002> end
=> nil
irb(main):003* class B < A
irb(main):004> end
=> nil
irb(main):005> A.ancestors
=> [A, B, Object, JSON::Ext::Generator::GeneratorMethods::Object, PP::ObjectMixin, Kernel, BasicObject]
```

#### Method resolution

When we call a method for an object, we look up its class and its ancestors, then look for a method with that name in each class, up the ancestor chain (left to right).

```ruby
irb(main):001* class A
irb(main):002*   def say
irb(main):003*     "aye"
irb(main):004*   end
irb(main):005> end
=> nil
irb(main):006* class B < A
irb(main):007*   def say
irb(main):008*     "bye"
irb(main):009*   end
irb(main):010> end
=> nil
irb(main):011> A.ancestors
=> [A, B, Object, JSON::Ext::Generator::GeneratorMethods::Object, PP::ObjectMixin, Kernel, BasicObject]
irb(main):012> B.ancestors
=> [B, Object, JSON::Ext::Generator::GeneratorMethods::Object, PP::ObjectMixin, Kernel, BasicObject]
```

Every class inherits from `Object`. The root of every class heirarchy is `BasicObject`. These define the most basic methods every object (everything) can call.

```ruby
irb(main):002> BasicObject.instance_methods
=> [:equal?, :!, :__send__, :==, :!=, :__id__, :instance_eval, :instance_exec]
```

### Classes are objects

Everything in Ruby is an object. 

Every object in Ruby has a class.

Even classes are objects. So they have a class too. They are objects with class `Class`.

```ruby
irb(main):001* class A
irb(main):002> end
=> nil
irb(main):003> A.class
=> Class
irb(main):004> A.instance_of? Class
=> true
```

The `class` keyword is just one way to give a `Class` a name.

```ruby
irb(main):001> Class.new
=> #<Class:0x000000011e21ee30>
irb(main):002> A = Class.new
=> A
irb(main):003> a = A.new
=> #<A:0x0000000128d3e360>
```

The class of `Class` is ... itself. Because it's a class!

```ruby
irb(main):001> Class.class
=> Class
```

It is an instance of itself.

```ruby
irb(main):002> Class.instance_of? Class
=> true
```

`Class` also has ancestors.

```ruby
irb(main):001> Class.ancestors
=> [Class, Module, Object, JSON::Ext::Generator::GeneratorMethods::Object, PP::ObjectMixin, Kernel, BasicObject]
```

It turns out all classes inherit from `Module`.

`Module` is also a class. Modules objects that are instances of `Module`.

```ruby
irb(main):001> Module.class
=> Class
irb(main):002* module B
irb(main):003> end
=> nil
irb(main):004> B.class
=> Module
```

A lot of things are a class, because everything is an object and objects have a class.

### Everything is an object

A "class" is an object that has a class of `Class`.

It can help to think of an object's class not as "what it is", but *as a property of the object*.

Indeed, in Ruby's internals, `klass` is [a property on a C struct](https://docs.ruby-lang.org/capi/en/master/d2/d22/struct_r_basic.html#a16e74a53ecb346b88c35e813bae8fe32) included on all objects. And everything is an object.

> - klass
>
> Class of an object.
>
> Every object has its class. Also, everything is an object in Ruby. This means classes are also objects. Classes have their own classes, classes of classes have their classes too, and it recursively continues forever.

So, `Class` is an object with a `klass` pointer to itself.

### Singleton classes and eigenclasses

So what's an eigenclass? 

It's a singleton class, of course! Singleton class is the official terminology now.

Okay, so what's a singleton class?

When you create an object from a class, the object creates and stores an anonymous class that inherits from the original class.

```ruby
irb(main):001* class A
irb(main):002> end
=> nil
irb(main):003> a = A.new
=> #<A:0x000000012275ded8>
irb(main):004> a.singleton_class
=> #<Class:#<A:0x000000012275ded8>>
irb(main):005> a.singleton_class.ancestors
=> [#<Class:#<A:0x000000012275ded8>>, A, Object, JSON::Ext::Generator::GeneratorMethods::Object, PP::ObjectMixin, Kernel, BasicObject]
```

Importantly, because this singleton class is created per instance, any methods set on the object's singleton class do not modify the object's regular class. 

When we call a method, we look up the method name on the instance-specific singleton class first. In Ruby internals, an object's class is secretly the singleton class, which inherits from the class the object was instantiated from, which allows method resolution to work down the ancestor chain as expected.

This is the point of the singleton class! It allows us to add or override methods at the object level without affecting other instances of the object class.

We can use the `def {obj}.{method_name}` or `class << {obj}` syntax to define a method on the singleton class for that instance.

```ruby
irb(main):001* class A
irb(main):002> end
=> nil
irb(main):003> a1 = A.new
=> #<A:0x0000000160650688>
irb(main):004> a2 = A.new
=> #<A:0x000000012f65aad8>
irb(main):005* def a1.hello
irb(main):006*   "hi"
irb(main):007> end
=> :hello
irb(main):008* class << a2
irb(main):009*   def bye
irb(main):010*     "cya"
irb(main):011*   end
irb(main):012> end
=> :bye
irb(main):013> a1.hello
=> "hi"
irb(main):014> a2.bye
=> "cya"
irb(main):015> a2.hello
(irb):15:in '<main>': undefined method 'hello' for #<A:0x000000012f65aad8> (NoMethodError)
irb(main):016> a3 = A.new
=> #<A:0x000000012f2d9620>
irb(main):017> a3.hello
(irb):17:in '<main>': undefined method 'hello' for #<A:0x000000012f2d9620> (NoMethodError)
irb(main):018> a1.bye
(irb):18:in '<main>': undefined method 'bye' for #<A:0x0000000160650688> (NoMethodError)
irb(main):019> a3.bye
(irb):19:in '<main>': undefined method 'bye' for #<A:0x000000012f2d9620> (NoMethodError)
```

### Class methods

This is also what allows class methods to be defined with the same `def self.{method_name}` or `class << self` syntax in a class body.

```ruby
class WithClassMethods
  def self.class_method_1
    "one"
  end

  class << self
    def self.class_method_2
      "two"
    end
  end
end

puts WithClassMethods.class_method_1
puts WithClassMethods.class_method_2
# WithClassMethods.new.class_method_1 => NoMethodError
# WithClassMethods.new.class_method_2 => NoMethodError
```

All classes are objects, all objects have singletons, so class `A` (which is an instance of `Class`) has a singleton class that we're modifying with the same syntax! The `self` in the class body points to class `A`.

```ruby
irb(main):001* class A
irb(main):002> end
=> nil
irb(main):003> A.singleton_class
=> #<Class:A>
irb(main):004* class A
irb(main):005*   def self.on_the_class_singleton
irb(main):006*     "yes"
irb(main):007*   end
irb(main):008> end
irb(main):009> 
irb(main):010> A.singleton_class.instance_methods.include?(:on_the_class_singleton)
=> true
```

The class singleton class inherits from the singleton classes of its ancestors, which is how you can call class methods defined on a parent class on a child class. 

```ruby
irb(main):001* class A
irb(main):002> end
=> nil
irb(main):003> class B < A; end
=> nil
irb(main):004> B.singleton_class
=> #<Class:B>
irb(main):005> B.singleton_class.ancestors
=> 
[#<Class:B>,
 #<Class:A>,
 #<Class:Object>,
 #<Class:BasicObject>,
 Class,
 Module,
 Object,
 JSON::Ext::Generator::GeneratorMethods::Object,
 PP::ObjectMixin,
 Kernel,
 BasicObject]
irb(main):006> B.new.singleton_class.ancestors
=> [#<Class:#<B:0x000000011ef7e2b0>>, B, A, Object, JSON::Ext::Generator::GeneratorMethods::Object, PP::ObjectMixin, Kernel, BasicObject]
```

Because every class is an object, class singletons are also an object, so this chain of inheritance repeats infinitely. Ruby lazily creates singleton classes, so does not repeat infinitely in practice, although you could access them infinitely.

```ruby
irb(main):001* class A
irb(main):002> end
=> nil
irb(main):003> a = A.new
=> #<A:0x0000000123a97d78>
irb(main):004> a.singleton_class.ancestors
=> [#<Class:#<A:0x0000000123a97d78>>, A, Object, JSON::Ext::Generator::GeneratorMethods::Object, PP::ObjectMixin, Kernel, BasicObject]
=> nil
irb(main):005> A.singleton_class.ancestors
=> 
[#<Class:A>,
 #<Class:Object>,
 #<Class:BasicObject>,
 Class,
 Module,
 Object,
 JSON::Ext::Generator::GeneratorMethods::Object,
 PP::ObjectMixin,
 Kernel,
 BasicObject]
irb(main):006> A.singleton_class.singleton_class
=> #<Class:#<Class:A>>
irb(main):007> A.singleton_class.singleton_class.ancestors
=> 
[#<Class:#<Class:A>>,
 #<Class:#<Class:Object>>,
 #<Class:#<Class:BasicObject>>,
 #<Class:Class>,
 #<Class:Module>,
 #<Class:Object>,
 #<Class:BasicObject>,
 Class,
 Module,
 Object,
 JSON::Ext::Generator::GeneratorMethods::Object,
 PP::ObjectMixin,
 Kernel,
 BasicObject]
irb(main):008> A.singleton_class.singleton_class.singleton_class.ancestors
=> 
[#<Class:#<Class:#<Class:A>>>,
 #<Class:#<Class:#<Class:Object>>>,
 #<Class:#<Class:#<Class:BasicObject>>>,
 #<Class:#<Class:Class>>,
 #<Class:#<Class:Module>>,
 #<Class:#<Class:Object>>,
 #<Class:#<Class:BasicObject>>,
 #<Class:Class>,
 #<Class:Module>,
 #<Class:Object>,
 #<Class:BasicObject>,
 Class,
 Module,
 Object,
 JSON::Ext::Generator::GeneratorMethods::Object,
 PP::ObjectMixin,
 Kernel,
 BasicObject]
```

`#<Class:A>` is the singleton class of class `A` (not the singleton class of an instance of `A`).

Because it is a class singleton class, it inherits the singleton classes of the ancestors of `A`, so the singleton classes of `Object` (`#<Class:Object>`) and `BasicObject` (`#<Class:BasicObject>`).

Since those singleton classes are themselves classes, the they eventually inherit from `Class`. We could repeat this for another layer, then we'd have the singleton class of `Class`, and so on and so forth.

In the diagram, the horizontal arrows going right should be labeled "is of class" and "has singleton class".

### Language is hard

Finally, "metaclass" means "class of a class". Only singleton classes of classes are metaclasses, what you use to you define a class method. A singleton class of a class instance is not a metaclass (in the past this terminology was conflated). 

In this case, `#<Class:A>` is a metaclass. Metaclasses eventually inherit from `Class`, since they are classes.

In summary:

1. Everything is an object
2. Objects have a class
3. Classes have methods
4. Classes have ancestors classes
5. Methods are found on classes and their ancestors
6. Classes are objects
7. Classes have a class
8. Objects create a singleton class that inherit from their usual class
9. Objects look up methods on their singleton class first
10. Class methods are methods on the singleton class of a class
11. Singleton classes have a singleton class
12. The singleton class of a class inherits from singleton classes of the class's ancestors

I think this explains what an eigenclass is, the entire infinitely recurring diagram from the beginning, as well as the rest of Ruby's object model.

Here is my extension to the diagram:

```
                         +---------+             +-...
                         |         |             |
         BasicObject--e--|-->(BasicObject)-------|-...
             ^           |         ^             |
             |           |         |             |
          Object--eigen--|----->(Object)---------|-...
             ^           |         ^             |
             |           |         |             |
             +-------+   |         +--------+    |
             |       |   |         |        |    |
             |    Module-|---------|--->(Module)-|-...
             |       ^   |         |        ^    |
             |       |   |         |        |    |
             |     Class-|---------|---->(Class)-|-...
             |       ^   |         |        ^    |
             |       +---+         |        +----+
             |                     |
           Animal----eigen----->(Animal)-----------...
             ^                     ^
             |                     |
   bob----->Dog------eigen------>(Dog)------------...
    |        ^
    V        |
   eigenbob -+
```

## References

Noel Rappin's "Better Know A Ruby Thing" series on Ruby singletons is the most valuable resource I used:
- [Better Know A Ruby Thing: Singleton Classes](https://noelrappin.com/blog/2025/01/better-know-a-ruby-thing-singleton-classes/)
- [Better Know A Ruby Thing: Method Lookup](https://noelrappin.com/blog/2025/03/better-know-a-ruby-thing-method-lookup/)


As short as the Ruby FAQ, but much more informational: [Singleton Classes in Ruby (aka eigenclasses)](https://codequizzes.wordpress.com/2014/04/11/singleton-classes-in-ruby-aka-eigenclasses/)


[Official Ruby syntax docs](https://docs.ruby-lang.org/en/3.4/syntax_rdoc.html):
- [Ruby docs: Singleton Classes](https://docs.ruby-lang.org/en/3.4/syntax/modules_and_classes_rdoc.html#label-Singleton+Classes)
- [Ruby docs: Method Lookup](https://docs.ruby-lang.org/en/3.4/syntax/calling_methods_rdoc.html#label-Method+Lookup)

This post from Yehuda Katz is good but I think predates standard terminology, so mentally replace every occurrence of "metaclass" with "singleton class": [Metaprogramming in Ruby: It's All About the Self](https://yehudakatz.com/2009/11/15/metaprogramming-in-ruby-its-all-about-the-self/)