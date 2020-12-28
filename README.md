# LoftTest_StandardLibraryProtocolChecks

`XCTest`s that a type obeys the semantic laws associated with its Swift standard library protocol
conformances.  For example, with this module imported, every `MutableCollection` type gets a
`checkMutableCollectionsLaws` method that can help validate that it has been properly defined.

The protocols currently supported are:

* `Collection`
* `Comparable`
* `Equatable`
* `Hashable`
* `MutableCollection`
* `RandomAccessCollection`
* `Sequence`

## Motivation

Say you have defined a `MutableCollection` called `FourStrings`.  How do you know it's correct?
Even if you have tested the methods you wrote directly, there's still a large API surface that comes
from its conformance to `MutableCollection`—the `sort()` method, for example—and any module can add
more APIs in an extension.  For these APIs to work properly, there's a set of **laws** that
`FourStrings`' protocol requirement implementations must follow.  For example, writing into an
element via subscript must update the indicated element to the right value, without modifying any
other elements or changing the length of the collection.  These laws are rather loosely implied by
the [`MutableCollection`
documentation](https://developer.apple.com/documentation/swift/mutablecollection), but are
*crucially important* in making `FourStrings` work as advertised.  Furthermore, `MutableCollection`
refines `Collection` and `Sequence`, each of which has laws of its own, and has associated types
like `Index`, `Indices`, `SubSequence` and `Iterator`, with *their* own laws.  This package allows
you to test conformance to all of these laws with one method call:

```swift
import XCTest
import LoftTest_StandardLibraryProtocolChecks

class FourStringsTests: XCTestCase {
  ...
  func testConformances() {
    var subject = FourStrings("one", "two", "three", "four")
    
    subject.checkMutableCollectionLaws( // <========= HERE
      expecting: ["one", "two", "three", "four"], writing: ["1", "2", "3", "4"])
  }
  ...
}
```

## Details

A few potentially-surprising design choices are worth discussing here.

### `Equatable` element requirement for `Collection` tests

One of the most basic features of a conforming `Collection` is that code making multiple passes over
its elements will observe the same sequence of values each time.  Naturally, testing that property
implies some way of measuring the “sameness” of two element values.  Therefore, the tests in this
package require that the `Element` types are `Equatable`.  If you need to test a collection with an
`Element` that is not `Equatable`, e.g. instances of some class `X`, you can extend `X` as follows,
in your testing module:

```swift
extension X: Equatable {
  static func == (a: X, b: X) -> Bool { a === b }
}
```

That said, most `Collection`s can usefully be made generic over their element types, and if you did
that to `X` you could tests `X<Int>`, since `Int` is `Equatable`.

### `RandomAccessCollection` tests only work for adapters

For testing `RandomAccessCollection` conformance, we faced an interesting problem:
`RandomAccessCollection` adds no *syntactic* requirements beyond those of `BidirectionalCollection`,
and the only new *semantic* requirements relate to performance.  For instance `index(i, offsetBy:
N)` is required to be at worst O(N) for a `Collection`, but `RandomAccessCollection` tightens that
requirement to O(1).  The default implementation of `index(i, offsetBy: n)` works by looping `n`
times, advancing `i` at each iteration, so it works great for anything that isn't a
`RandomAccessCollection`.  However, that same implementation makes it really easy to define a
`RandomAccessCollection` that compiles and gives correct results with the wrong performance, which
in turn ruins the performance of important algorithms such as `sort()`.  Because of some [language
quirks](https://forums.swift.org/t/ergonomics-generic-types-conforming-in-more-than-one-way/34589),
it's especially easy to make this mistake when the collection's conformance relies on conditional
protocol extensions.

For most collections, we have no deterministic way of checking how the performance of
`index(_:offsetBy:)` scales (it would be interesting to investigate benchmark-like tests checking
the performance of operations such as `index(_:offsetBy:)` but that capability is beyond the current
scope of this package). For collection *adapters*, though, we can count the number of
`index(after:)` operations invoked by `index(_:offsetBy:)`, thus revealing when `index(_:offsetBy:)`
hasn't been explicitly implemented.  A **collection adapter** is a collection that adapts some
underlying generic “base” `Collection` to alter its behavior.  There are several examples in the
standard library, e.g. `LazyMapCollection` and `ReversedCollection`.  To test `ReversedCollection`,
there are three steps:

1. Declare its conformance to `RandomAccessCollectionAdapter`:

    ```swift
    extension ReversedCollection: RandomAccessCollectionAdapter
      where Base: RandomAccessCollection {}
    ```

2. Adapt a special base collection called `RandomAccessOperationCounter`:

    ```swift
    let base = RandomAccessOperationCounter(0..<20)
    let adapter: ReversedCollection = base.reversed()
    ```

3. Pass the base collection along to the adapter's `checkRandomAccessCollectionLaws` method:

    ```swift
    let expectedElements = (0..<20).map { 19 - $0 }
    adapter.checkRandomAccessCollectionLaws(
      expecting: expectedElements,
      operationCounts: base.operationCounts)
    ```
    
You can find a more complete example in the documentation for `RandomAccessCollectionAdapter`.

### Optional “equivalent instance” parameters

Some types have what are known as “[non-salient attributes](https://youtu.be/W3xI1HJUy7Q),” that
shouldn't affect their notion of equality or hash value.  For instance, two `Array<Int>`s can be
equal even when they have different `capacity`, because `capacity` is a non-salient attribute of
`Array`.  Occasionally, especially with types that have remote parts, a property that should be
non-salient, such as a cache, or a *pointer to* the type's actual value, may be exposed
unintentionally.  In the `UnsafePointer`-to-value case, the default conformance to `Equatable`
synthesized by the compiler will happily do that for you.

For structurally-simple types with no risk of such mistakes, it's sufficient to test their
conformance to `Equatable`, `Hashable`, or `Comparable` with the fewest possible explicit arguments:

```swift
func testHashableInts() {
  let examples = [Int.min, -2, -1, 0, 1, 2, Int.max]
  for i in examples {
    i.checkHashableLaws() // <======== HERE
  }
}
```

But for more interesting types, the tests accept optional `equal:` arguments that allow the library
to probe for likely problems:

```swift
func testHashableArrays() {
  let a = Array(0..<10)
  var b = Array(0..<10)
  var c = Array(0..<10)
  // Ensure `a`, `b`, and `c` have distinct internal representations
  b.reserveCapacity(a.capacity * 2)
  c.reserveCapacity(b.capacity * 2) 
  
  // Pass the distinct-but-equal instances `b` and `c` to the check.
  a.checkHashableLaws(equal: b, c) // <======= HERE
}
```
