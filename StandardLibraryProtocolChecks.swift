// Copyright 2020 The Penguin Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest

extension Equatable {
  /// XCTests `Self`'s conformance to `Equatable`, given equivalent instances
  /// `self`, `self1`, and `self2`.
  ///
  /// If `Self` has a distinguishable identity or any remote parts, `self`, `self1`, and `self2`
  /// should not be trivial copies of each other.  In other words, the instances should be as
  /// different as possible internally, while still being equal.  Otherwise, it's fine to pass `nil`
  /// (the default) for `self1` and `self2`.
  public func checkEquatableLaws(equal self1: Self? = nil, _ self2: Self? = nil) {
    let self1 = self1 ?? self
    let self2 = self2 ?? self
    
    XCTAssertEqual(self, self, "Equatable conformance: == lacks reflexivity.")
    XCTAssertEqual(self1, self1, "Equatable conformance: == lacks reflexivity.")
    XCTAssertEqual(self2, self2, "Equatable conformance: == lacks reflexivity.")
    
    XCTAssertEqual(self1, self, "Equatable conformance: == lacks symmetry.")
    XCTAssertEqual(self2, self1, "Equatable conformance: == lacks symmetry.")

    XCTAssertEqual(self, self2, "Equatable conformance: == lacks transitivity.")
  }
}

extension Hashable {
  /// XCTests `Self`'s conformance to `Hashable`, given equivalent instances
  /// `self`, `self1`, and `self2`.
  ///
  /// If `Self` has a distinguishable identity or any remote parts, `self`, `self1`, and `self2`
  /// should not be trivial copies of each other.  In other words, the instances should be as
  /// different as possible internally, while still being equal.  Otherwise, it's fine to pass `nil`
  /// (the default) for `self1` and `self2`.
  public func checkHashableLaws(equal self1: Self? = nil, _ self2: Self? = nil) {
    checkEquatableLaws(equal: self1, self2)
    let self1 = self1 ?? self
    let self2 = self2 ?? self
    let message = "Equal instances have distinct hash values"
    XCTAssertEqual(self.hashValue, self1.hashValue, message)
    XCTAssertEqual(self.hashValue, self2.hashValue, message)
  }
}

extension Comparable {
  /// XCTests that `self` obeys all comparable laws with respect to an equivalent instance
  /// `self1`.
  ///
  /// If `Self` has a distinguishable identity or any remote parts, `self` and `self1` should
  /// not be trivial copies of each other.  In other words, the instances should be as different as
  /// possible internally, while still being equal.  Otherwise, it's fine to pass `nil` (the
  /// default) for `self1`.
  ///
  /// - Precondition: `self == (self1 ?? self)`
  private func checkComparableUnordered(equal self1: Self? = nil) {
    let self1 = self1 ?? self
    // Comparable still has distinct requirements for <,>,<=,>= so we need to check them all :(
    // Not Using XCTAssertLessThanOrEqual et al. because we don't want to be reliant on them calling
    // the operators literally; there are other ways they could be implemented.
    XCTAssertFalse(self < self1)
    XCTAssertFalse(self > self1)
    XCTAssertFalse(self1 < self)
    XCTAssertFalse(self1 > self)
    XCTAssert(self <= self1)
    XCTAssert(self >= self1)
    XCTAssert(self1 <= self)
    XCTAssert(self1 >= self)
  }

  /// XCTests that `self` obeys all comparable laws with respect to a greater value `greater`.
  private func checkComparableOrdering(greater: Self) {
    XCTAssert(self < greater, "Possible mis-test; \(self) ≮ \(greater).")
    // Comparable still has distinct requirements for <,>,<=,>= so we need to check them all :(
    
    // Not Using XCTAssertLessThanOrEqual et al. because we don't want to be reliant on them calling
    // the operators literally; there are other ways they could be implemented.
    XCTAssert(self <= greater)
    XCTAssertNotEqual(self, greater)
    XCTAssertFalse(self >= greater)
    XCTAssertFalse(self > greater)

    XCTAssertFalse(greater < self)
    XCTAssertFalse(greater <= self)
    XCTAssert(greater >= self)
    XCTAssert(greater > self)
  }
  
  /// XCTests `Self`'s conformance to `Comparable`.
  ///
  /// If `Self` has a distinguishable identity or any remote parts, `self`, `self1`, and `self2`
  /// should be equivalent, but should not be trivial copies of each other.  In other words, the
  /// instances should be as different as possible internally, while still being equal.  Otherwise,
  /// it's fine to pass `nil` (the default) for `self1` and `self2`.
  ///
  /// If distinct values for `greater` or `greaterStill` are unavailable (e.g. when `Self` only has
  /// one or two values), the caller may pass `nil` values. Callers are encouraged to pass non-`nil`
  /// values whenever they are available, because they enable more checks.
  ///
  /// - Precondition: `self == (self1 ?? self) && self1 == (self2 ?? self)`.
  /// - Precondition: if `greaterStill != nil`, `greater != nil`.
  /// - Precondition: if `greater != nil`, `self < greater!`.
  /// - Precondition: if `greaterStill != nil`, `greater! < greaterStill!`.
  public func checkComparableLaws(
    equal self1: Self? = nil, _ self2: Self? = nil, greater: Self?, greaterStill: Self?
  ) {
    precondition(
      greater != nil || greaterStill == nil, "`greaterStill` should be `nil` when `greater` is.")

    checkEquatableLaws(equal: self1, self2)
    
    self.checkComparableUnordered(equal: self)
    self.checkComparableUnordered(equal: self1)
    self.checkComparableUnordered(equal: self2)
    (self1 ?? self).checkComparableUnordered(equal: self2)
    greater?.checkComparableUnordered()
    greaterStill?.checkComparableUnordered()

    if let greater = greater {
      self.checkComparableOrdering(greater: greater)
      if let greaterStill = greaterStill {
        greater.checkComparableOrdering(greater: greaterStill)
        // Transitivity
        self.checkComparableOrdering(greater: greaterStill)
      }
    }
  }

  /// Given three unequal instances, returns them in increasing order, relying only on <.
  ///
  /// This function can be useful for checking comparable conformance in conditions where you know
  /// you have unequal instances, but can't control the ordering.
  ///
  ///     let (min, mid, max) = X.sort3(X(a), X(b), X(c))
  ///     min.checkComparableLaws(greater: mid, greaterStill: max)
  ///
  public static func sort3(_ a: Self, _ b: Self, _ c: Self) -> (Self, Self, Self) {
    precondition(a != b)
    precondition(a != c)
    precondition(b != c)
    
    let min = a < b
      ? a < c ? a : c
      : b < c ? b : c
    
    let max = a < b
      ? b < c ? c : b
      : a < c ? c : a
    
    let mid = a < b
      ? b < c
          ? b 
          : a < c ? c : a
      : a < c 
	        ? a
          : b < c ? c : b

    return (min, mid, max)
  }
}

// *********************************************************************
// Checking sequence/collection semantics.  Note that these checks cannot see
// any declarations that happen to shadow the protocol requirements. Those
// shadows have to be tested separately.

extension Sequence where Element: Equatable {
  /// XCTests `self`'s semantic conformance to `Sequence`, expecting its
  /// elements to match `expectedContents`.
  ///
  /// - Complexity: O(N), where N is `expectedContents.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  public func checkSequenceLaws<
    ExampleContents: Collection>(expecting expectedContents: ExampleContents)
    where ExampleContents.Element == Element
  {
    var i = self.makeIterator()
    var remainder = expectedContents[...]
    while let x = i.next() {
      XCTAssertEqual(
        remainder.popFirst(), x, "Sequence contents don't match expectations.")
    }
    XCTAssert(
      remainder.isEmpty,
      "Expected tail elements \(Array(remainder)) not present in Sequence.")
    XCTAssertEqual(
      i.next(), nil,
      "Exhausted iterator expected to return nil from next() in perpetuity.")
  }
}

extension Collection where Element: Equatable {
  /// XCTests `self`'s semantic conformance to `Collection`, expecting its
  /// elements to match `expectedContents`.
  ///
  /// - Parameter maxSupportedCount: the maximum number of elements that instances of `Self` can
  ///   have.
  ///
  /// - Requires: `self.count >= min(2, maxSupportedCount)`.
  /// - Complexity: O(N²), where N is `self.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  public func checkCollectionLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents, maxSupportedCount: Int = Int.max
  ) where ExampleContents.Element == Element {
    precondition(
      self.count >= Swift.min(2, maxSupportedCount),
      "must have at least \(Swift.min(2, maxSupportedCount)) elements.")

    
    if startIndex == endIndex {
      startIndex.checkEquatableLaws()
    }
    
    checkSequenceLaws(expecting: expectedContents)

    if Self.self != Indices.self {
      indices.checkCollectionLaws(expecting: indices)
    }
    if Self.self != SubSequence.self {
      self[...].checkCollectionLaws(expecting: expectedContents)
    }
    
    var i = startIndex
    var firstPassElements: [Element] = []
    var remainingCount: Int = expectedContents.count
    var offset: Int = 0
    var expectedIndices = indices
    var sequenceElements = makeIterator()
    var priorIndex: Index? = nil

    // NOTE: if you edit this loop, you probably want to edit the inverse one for
    // checkBidirectionalCollectionLaws below!
    while i != endIndex {
      let expectedIndex = expectedIndices.popFirst()
      XCTAssertEqual(
        i, expectedIndex,
        "elements of indices property don't match index(after:) results.")
      
      XCTAssertLessThan(i, endIndex)
      let j = self.index(after: i)
      XCTAssertLessThan(i, j, "indices are not strictly increasing.")
      if let h = priorIndex { h.checkComparableLaws(greater: i, greaterStill: j) }
      else { i.checkComparableLaws(greater: j, greaterStill: nil) }
      let e = self[i]
      firstPassElements.append(e)
      XCTAssertEqual(sequenceElements.next(), e, "iterator/subscript access mismatch.")
      
      XCTAssertEqual(
        index(i, offsetBy: remainingCount), endIndex,
        "index(offsetBy:) offset >= 0, unexpected result.")
      
      if offset != 0 {
        XCTAssertEqual(
          index(startIndex, offsetBy: offset - 1, limitedBy: i),
          index(startIndex, offsetBy: offset - 1),
          "index(offsetBy:limitedBy:) offset >= 0: limit not exceeded but had effect.")
      }
      
      for n in 0..<remainingCount {
        XCTAssertEqual(
          index(i, offsetBy: n, limitedBy: endIndex), index(i, offsetBy: n),
          "index(offsetBy:limitedBy: endIndex) offset >= 0, limit not exceeded but had effect.")
      }
      
      XCTAssertEqual(
        index(startIndex, offsetBy: offset, limitedBy: i), i,
        "index(offsetBy:limitedBy:) offset >= 0, limit not exceeded but had effect."
      )
      
      if remainingCount != 0 {
        XCTAssertEqual(
          index(startIndex, offsetBy: offset + 1, limitedBy: i), nil,
          "index(offsetBy:limitedBy:) offset > 0, limit not respected.")
      }
      
      XCTAssertEqual(
        distance(from: i, to: endIndex), remainingCount,
        "distance(from: i, to: j), i < j unexpected result.")
      
      priorIndex = i
      i = j
      remainingCount -= 1
      offset += 1
    }

    XCTAssertEqual(
      index(endIndex, offsetBy: 0, limitedBy: endIndex), endIndex,
      "index(offsetBy:limitedBy:) offset >= 0, limit not exceeded but had effect.")

    
    XCTAssertEqual(
      nil, expectedIndices.popFirst(), "indices property has too many elements.")
    
    // Check that the second pass has the same elements.  
    XCTAssert(firstPassElements.elementsEqual(expectedContents), "Collection is not multipass.")
  }
}

extension BidirectionalCollection where Element: Equatable {
  /// XCTests `self`'s semantic conformance to `BidirectionalCollection`,
  /// expecting its elements to match `expectedContents`.
  ///
  /// - Parameter maxSupportedCount: the maximum number of elements that instances of `Self` can
  ///   have.
  ///
  /// - Requires: `self.count >= min(2, maxSupportedCount)`.
  /// - Complexity: O(N²), where N is `self.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  public func checkBidirectionalCollectionLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents, maxSupportedCount: Int = Int.max
  ) where ExampleContents.Element == Element {
    checkCollectionLaws(
      expecting: expectedContents, maxSupportedCount: maxSupportedCount)
    
    if Self.self != Indices.self {
      indices.checkBidirectionalCollectionLaws(expecting: indices)
    }
    if Self.self != SubSequence.self {
      self[...].checkBidirectionalCollectionLaws(expecting: expectedContents)
    }

    var i = endIndex
    var remainingCount: Int = expectedContents.count
    var offset: Int = 0
    
    while i != startIndex {
      XCTAssertGreaterThan(i, startIndex)
      let j = self.index(before: i)
      XCTAssertEqual(index(after: j), i, "index(after:) does not undo index(before:).")
      
      XCTAssertEqual(
        index(i, offsetBy: -remainingCount), startIndex,
        "index(offsetBy:) offset <= 0, unexpected result.")
      
      if offset != 0 {
        XCTAssertEqual(
          index(endIndex, offsetBy: -(offset - 1), limitedBy: i),
          index(endIndex, offsetBy: -(offset - 1)),
          "wrong unlimited result from index(offsetBy:limitedBy:).")
      }
      
      for n in 0..<remainingCount {
        XCTAssertEqual(
          index(i, offsetBy: -n, limitedBy: startIndex), index(i, offsetBy: -n),
          "index(offsetBy:limitedBy: startIndex) offset <= 0, limit not exceeded but had effect.")
      }
      
      XCTAssertEqual(
        index(endIndex, offsetBy: -offset, limitedBy: i), i,
        "wrong unlimited result from index(offsetBy:limitedBy:).")
      
      if remainingCount != 0 {
        XCTAssertEqual(
          index(endIndex, offsetBy: -(offset + 1), limitedBy: i), nil,
          "index(offsetBy:limitedBy:) offset < 0, limit not respected.")
      }
      
      XCTAssertEqual(
        distance(from: i, to: startIndex), -remainingCount,
        "distance(from: i, to: j), j < i unexpected result.")
      
      i = j
      remainingCount -= 1
      offset += 1
    }
    
    XCTAssertEqual(
      index(startIndex, offsetBy: 0, limitedBy: startIndex), startIndex,
      "wrong unlimited result from index(offsetBy:limitedBy:).")
  }
}

/// Shared storage for operation counts.
///
/// This is a class:
/// - so that increments aren't missed due to copies
/// - because non-mutating operations on `RandomAccessOperationCounter` have
///   to update it.
public final class RandomAccessOperationCounts {
  /// The number of invocations of `index(after:)`
  public var indexAfter: Int = 0
  /// The number of invocations of `index(before:)`
  public var indexBefore: Int = 0

  /// Creates an instance with zero counter values.
  fileprivate init() {}
  
  /// Reset all counts to zero.
  public func reset() { (indexAfter, indexBefore) = (0, 0) }
}

/// A “shadow protocol” for `RandomAccessOperationCounter`, below, to work around the lack of
/// [placeholder types in generic
/// constraints](https://forums.swift.org/t/placeholder-types/41329/45).
public protocol RandomAccessOperationCounterProtocol {
  /// The type of collection being augmented with index movement counters
  associatedtype Base: Collection

  /// The collection being augmented with index movement counters.
  var base: Base { get }

  /// The operation counters.
  var operationCounts: RandomAccessOperationCounts { get }
}

/// A wrapper over some `Base` collection that augments the base by counting index
/// increment/decrement operations performed.
///
/// This wrapper is useful for verifying that generic collection adapters that
/// conditionally conform to `RandomAccessCollection` are actually providing the
/// correct complexity. See `RandomAccessCollectionAdapter` for examples.
///
public struct RandomAccessOperationCounter<Base: RandomAccessCollection>
  : RandomAccessOperationCounterProtocol
{
  public var base: Base
  
  public typealias Index = Base.Index
  public typealias Element = Base.Element

  /// The number of index increment/decrement operations applied to `self` and
  /// all its copies.
  public var operationCounts = RandomAccessOperationCounts()

  public init(_ base: Base) { self.base = base }
}

extension RandomAccessOperationCounter: RandomAccessCollection {
  /// The position of the first element.
  public var startIndex: Index { base.startIndex }
  
  /// The position one step beyond the last element.
  public var endIndex: Index { base.endIndex }

  /// Accesses the element at `i`.
  public subscript(i: Index) -> Base.Element { base[i] }

  /// Returns the position immediately after `i`.
  public func index(after i: Index) -> Index {
    operationCounts.indexAfter += 1
    return base.index(after: i)
  }

  /// Returns the position immediately before `i`.
  public func index(before i: Index) -> Index {
    operationCounts.indexBefore += 1
    return base.index(before: i)
  }

  /// Replaces `i` with its successor.
  public func formIndex(after i: inout Index) {
    operationCounts.indexAfter += 1
    return base.formIndex(after: &i)
  }
  
  /// Replaces `i` with its predecessor.
  public func formIndex(before i: inout Index) {
    operationCounts.indexBefore += 1
    return base.formIndex(before: &i)
  }

  /// Returns the position `n` forward steps from `i`, where -1 forward steps is a backward step.
  public func index(_ i: Index, offsetBy n: Int) -> Index {
    base.index(i, offsetBy: n)
  }

  /// Returns `index(i, offsetBy: n)` unless `limit` is passed in the course of that traversal, in
  /// which case `nil` is returned.
  public func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    base.index(i, offsetBy: n, limitedBy: limit)
  }

  /// Returns the number of forward steps it takes to get from `i` to `j`, where -1 forward steps is
  /// a reverse step.
  public func distance(from i: Index, to j: Index) -> Int {
    base.distance(from: i, to: j)
  }
}

/// Generic `RandomAccessCollection` types that adapt some `Base` collection and can be tested for
/// conformance to random access efficiency constraints.
///
/// Use this to test your own adapters.  For example, to test this:
///     
///     /// A Really simple adapter over any `Base` that presents the same elements.
///     struct TrivialAdapter<Base: RandomAccessCollection>: RandomAccessCollection {
///       var base: Base
///       typealias Index = Base.Index
///       var startIndex: Base.Index { base.startIndex }
///       var endIndex: Base.Index { base.endIndex }
///     
///       subscript(i: Index) -> Base.Element { base[i] }
///     
///       func index(after i: Index) -> Index { return base.index(after: i) }
///       func index(before i: Index) -> Index { return base.index(before: i) }
///
///       // Note: the following will have the wrong performance for RandomAccessCollection
///       // conformance unless they are implemented:
///       //
///       // - index(:offsetBy:) 
///       // - index(:offsetBy:limitedBy:)
///       // - distance(from:to)
///     }
///
/// First, make it conform to `RandomAccessCollectionAdapter`:
///
///     extension TrivialAdapter: RandomAccessCollectionAdapter {}
///
/// Then you can test that it conforms as follows (this example will fail if you try it):
///
///     class TestExample: XCTestCase {
///       func testLaws() {
///         // Create a collection with operation counting.
///         let counter = RandomAccessOperationCounter(0..<20)
///         
///         // Now adapt it with our adapter.
///         let testSubject = TrivialAdapter(base: counter)
///
///         // And make sure that behaves.
///         testSubject.checkRandomAccessCollectionLaws(
///           expecting: 0..<20, operationCounts: counter.operationCounts),
///       }
///     }
///     
public protocol RandomAccessCollectionAdapter: Collection {
  associatedtype Base: Collection
}

extension RandomAccessCollectionAdapter
where Self: RandomAccessCollection,
      Element: Equatable,
      Base: RandomAccessOperationCounterProtocol
{
  /// XCTests `self`'s semantic conformance to `RandomAccessCollection`, expecting its elements to
  /// match `expectedContents`.
  ///
  /// - Parameter operationCounts: an instance that tracks operations in the `Base` collection that
  ///   `self` wraps.
  /// - Parameter maxSupportedCount: the maximum number of elements that instances of `Self` can
  ///   have.
  ///
  /// - Requires: `self.count >= min(2, maxSupportedCount)`.
  /// - Complexity: O(N²), where N is `self.count`.
  public func checkRandomAccessCollectionLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents,
    operationCounts: RandomAccessOperationCounts,
    maxSupportedCount: Int = Int.max
  )
  where ExampleContents.Element == Element
  {
    checkBidirectionalCollectionLaws(
      expecting: expectedContents, maxSupportedCount: maxSupportedCount)
    operationCounts.reset()
    XCTAssertEqual(distance(from: startIndex, to: endIndex), count)
    XCTAssertLessThanOrEqual(
      operationCounts.indexAfter, 1,
      "distance(from: i, to: j) i <= j is not O(1); did you forget to implement it?")
    XCTAssertLessThanOrEqual(
      operationCounts.indexBefore, 1,
      "distance(from: i, to: j) i <= j is not O(1); did you forget to implement it?")
    
    operationCounts.reset()
    XCTAssertEqual(distance(from: endIndex, to: startIndex), -count)
    XCTAssertLessThanOrEqual(
      operationCounts.indexAfter, 1,
      "distance(from: i, to: j) j <= i is not O(1); did you forget to implement it?")
    XCTAssertLessThanOrEqual(
      operationCounts.indexBefore, 1,
      "distance(from: i, to: j) j <= i is not O(1); did you forget to implement it?")

    operationCounts.reset()
    XCTAssertEqual(index(startIndex, offsetBy: count), endIndex)
    XCTAssertLessThanOrEqual(
      operationCounts.indexAfter, 1,
      "index(:offsetBy: i) i >= 0 is not O(1); did you forget to implement it?")
    XCTAssertLessThanOrEqual(
      operationCounts.indexBefore, 1,
      "index(:offsetBy: i) i >= 0 is not O(1); did you forget to implement it?")
    
    operationCounts.reset()
    XCTAssertEqual(index(endIndex, offsetBy: -count), startIndex)
    XCTAssertLessThanOrEqual(
      operationCounts.indexAfter, 1,
      "index(:offsetBy: i) i <= 0 is not O(1); did you forget to implement it?")
    XCTAssertLessThanOrEqual(
      operationCounts.indexBefore, 1,
      "index(:offsetBy: i) i <= 0 is not O(1); did you forget to implement it?")

    operationCounts.reset()
    XCTAssertEqual(
      index(startIndex, offsetBy: count, limitedBy: endIndex), endIndex)
    XCTAssertLessThanOrEqual(
      operationCounts.indexAfter, 1,
      "index(:offsetBy: i, limitedBy:) i >= 0 is not O(1); did you forget to implement it?")
    XCTAssertLessThanOrEqual(
      operationCounts.indexBefore, 1,
      "index(:offsetBy: i, limitedBy:) i >= 0 is not O(1); did you forget to implement it?")
    
    operationCounts.reset()
    XCTAssertEqual(
      index(endIndex, offsetBy: -count, limitedBy: startIndex), startIndex)
    XCTAssertLessThanOrEqual(
      operationCounts.indexAfter, 1,
      "index(:offsetBy: i, limitedBy:) i <= 0 is not O(1); did you forget to implement it?")
    XCTAssertLessThanOrEqual(
      operationCounts.indexBefore, 1,
      "index(:offsetBy: i, limitedBy:) i <= 0 is not O(1); did you forget to implement it?")
  }
}

extension MutableCollection where Element: Equatable {
  /// XCTests `self`'s semantic conformance to `MutableCollection`.
  ///
  /// - Precondition: `count == distinctContents.count`
  /// - Precondition: `zip(self, distinctContents).allSatisfy { $0 != $1 }`
  public mutating func checkMutableCollectionLaws<C0: Collection, C1: Collection>(
    expecting expectedContents: C0, writing distinctContents: C1
  )
    where C0.Element == Element, C1.Element == Element
  {
    XCTAssertEqual(
      count, distinctContents.count, "distinctContents must have the same length as self.")
    XCTAssert(
      zip(expectedContents, distinctContents).allSatisfy { $0 != $1 },
      "corresponding elements of self and distinctContents must be unequal.")

    checkCollectionLaws(expecting: expectedContents)

    let originalEndIndex = endIndex
    let originalContents = Array(self)
    let myIndices = Array(indices)

    // Forward pass testing subscript set
    for (i, (j, k)) in zip(myIndices, zip(distinctContents.indices, originalContents.indices)) {
      self[i] = distinctContents[j]
      XCTAssertEqual(
        self[i], distinctContents[j],
        "subscript set did not persist the new value.")
      XCTAssert(
        self[..<i].dropLast().elementsEqual(distinctContents[..<j].dropLast()),
        "subscript set mutated earlier element.")
      XCTAssert(
        self[i...].dropFirst().elementsEqual(originalContents[k...].dropFirst()),
        "subscript set mutated later element or changed count.")
    }

    // Backward pass testing subscript modify
    for (i, (j, k)) in zip(
          myIndices.reversed(),
          zip(distinctContents.indices.reversed(), originalContents.indices.reversed())) {

      func modify(_ e: inout Element, writing x: Element) {
        XCTAssertEqual(
          e, distinctContents[j],
          "subscript modify did not expose the old element value for mutation.")
        e = x
      }
      
      modify(&self[i], writing: originalContents[k])
      
      XCTAssertEqual(
        self[i], originalContents[k],
        "subscript modify did not persist the new value.")
      XCTAssert(
        self[..<i].dropLast().elementsEqual(distinctContents[..<j].dropLast()),
        "subscript modify mutated earlier element.")
      XCTAssert(
        self[i...].dropFirst().elementsEqual(originalContents[k...].dropFirst()),
        "subscript modify mutated later element or changed count.")
    }
    
    if Self.self != SubSequence.self {
      self[..<originalEndIndex]
        .checkMutableCollectionLaws(expecting: expectedContents, writing: distinctContents)
    }
  }
}

// Local Variables:
// fill-column: 100
// End:
