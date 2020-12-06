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
    
    XCTAssertEqual(self, self, "Equatable conformance: == lacks reflexivity")
    XCTAssertEqual(self1, self1, "Equatable conformance: == lacks reflexivity")
    XCTAssertEqual(self2, self2, "Equatable conformance: == lacks reflexivity")
    
    XCTAssertEqual(self1, self, "Equatable conformance: == lacks symmetry")
    XCTAssertEqual(self2, self1, "Equatable conformance: == lacks symmetry")

    XCTAssertEqual(self, self2, "Equatable conformance: == lacks transitivity")
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
    XCTAssert(self < greater, "Possible mis-test; \(self) ≮ \(greater)")
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
      greater != nil || greaterStill == nil, "`greaterStill` should be `nil` when `greater` is")

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
        remainder.popFirst(), x, "Sequence contents don't match expectations")
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
  /// - Requires: `self.count >= 2 || self.count >= maxSupportedCount`.
  /// - Complexity: O(N²), where N is `self.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  public func checkCollectionLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents, maxSupportedCount: Int = Int.max
  ) where ExampleContents.Element == Element {
    precondition(
      self.count >= Swift.min(2, maxSupportedCount),
      "must have at least \(Swift.min(2, maxSupportedCount)) elements")

    
    if startIndex == endIndex {
      startIndex.checkEquatableLaws()
    }
    
    checkSequenceLaws(expecting: expectedContents)
    
    var i = startIndex
    var firstPassElements: [Element] = []
    var remainingCount: Int = expectedContents.count
    var offset: Int = 0
    var expectedIndices = indices
    var sequenceElements = makeIterator()
    var priorIndex: Index? = nil
    
    while i != endIndex {
      let expectedIndex = expectedIndices.popFirst()
      XCTAssertEqual(
        i, expectedIndex,
        "elements of indices property don't match index(after:) results.")
      
      XCTAssertLessThan(i, endIndex)
      let j = self.index(after: i)
      XCTAssertLessThan(i, j, "indices are not strictly increasing")
      if let h = priorIndex { h.checkComparableLaws(greater: i, greaterStill: j) }
      else { i.checkComparableLaws(greater: j, greaterStill: nil) }
      let e = self[i]
      firstPassElements.append(e)
      XCTAssertEqual(sequenceElements.next(), e, "iterator/subscript access mismatch.")
      
      XCTAssertEqual(
        index(i, offsetBy: remainingCount), endIndex, "wrong result from index(offsetBy:)")
      
      if offset != 0 {
        XCTAssertEqual(
          index(startIndex, offsetBy: offset - 1, limitedBy: i),
          index(startIndex, offsetBy: offset - 1),
          "wrong unlimited result from index(offsetBy:limitedBy:)")
      }
      
      for n in 0..<remainingCount {
        XCTAssertEqual(
          index(i, offsetBy: n, limitedBy: endIndex), index(i, offsetBy: n),
          "wrong unlimited result from index(offsetBy:limitedBy:)")
      }
      
      XCTAssertEqual(
        index(startIndex, offsetBy: offset, limitedBy: i), i,
        "wrong unlimited result from index(offsetBy:limitedBy:)"
      )
      
      if remainingCount != 0 {
        XCTAssertEqual(
          index(startIndex, offsetBy: offset + 1, limitedBy: i), nil,
          "limit not respected by index(offsetBy:limitedBy:)"
        )
      }
      
      XCTAssertEqual(
        distance(from: i, to: endIndex), remainingCount, "distance(from:to:) wrong result")
      XCTAssertEqual(
        distance(from: endIndex, to: i),
        -remainingCount, "negative distance(from:to:) wrong result")

      priorIndex = i
      i = j
      remainingCount -= 1
      offset += 1
    }

    XCTAssertEqual(
      index(endIndex, offsetBy: 0, limitedBy: endIndex), endIndex,
      "wrong unlimited result from index(offsetBy:limitedBy:)")

    
    XCTAssertEqual(
      nil, expectedIndices.popFirst(), "indices property has too many elements.")
    
    XCTAssert(firstPassElements.elementsEqual(expectedContents), "Collection is not multipass")
    
    // Check that the second pass has the same elements.  
    XCTAssert(indices.lazy.map { self[$0] }.elementsEqual(expectedContents))
  }
}

extension BidirectionalCollection where Element: Equatable {
  /// XCTests `self`'s semantic conformance to `BidirectionalCollection`,
  /// expecting its elements to match `expectedContents`.
  ///
  /// - Parameter maxSupportedCount: the maximum number of elements that instances of `Self` can
  ///   have.
  ///
  /// - Requires: `self.count >= 2 || self.count >= maxSupportedCount`.
  /// - Complexity: O(N²), where N is `self.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  public func checkBidirectionalCollectionLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents, maxSupportedCount: Int = Int.max
  ) where ExampleContents.Element == Element {
    checkCollectionLaws(
      expecting: expectedContents, maxSupportedCount: maxSupportedCount)
    var i = startIndex
    while i != endIndex {
      let j = index(after: i)
      XCTAssertEqual(index(before: j), i)
      let offset = distance(from: i, to: startIndex)
      XCTAssertLessThanOrEqual(offset, 0)
      XCTAssertEqual(index(i, offsetBy: offset), startIndex)
      i = j
    }
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
  public init() {}
  
  /// Reset all counts to zero.
  public func reset() { (indexAfter, indexBefore) = (0, 0) }
}


/// A wrapper over some `Base` collection that counts index increment/decrement
/// operations.
///
/// This wrapper is useful for verifying that generic collection adapters that
/// conditionally conform to `RandomAccessCollection` are actually providing the
/// correct complexity.
public struct RandomAccessOperationCounter<Base: RandomAccessCollection> {
  public var base: Base
  
  public typealias Index = Base.Index
  public typealias Element = Base.Element

  /// The number of index incrementat/decrement operations applied to `self` and
  /// all its copies.
  public var operationCounts = RandomAccessOperationCounts()
}

extension RandomAccessOperationCounter: RandomAccessCollection {  
  public var startIndex: Index { base.startIndex }
  public var endIndex: Index { base.endIndex }
  public subscript(i: Index) -> Base.Element { base[i] }
  
  public func index(after i: Index) -> Index {
    operationCounts.indexAfter += 1
    return base.index(after: i)
  }
  public func index(before i: Index) -> Index {
    operationCounts.indexBefore += 1
    return base.index(before: i)
  }
  public func index(_ i: Index, offsetBy n: Int) -> Index {
    base.index(i, offsetBy: n)
  }

  public func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    base.index(i, offsetBy: n, limitedBy: limit)
  }

  public func distance(from i: Index, to j: Index) -> Int {
    base.distance(from: i, to: j)
  }
}

extension RandomAccessCollection where Element: Equatable {
  /// XCTests `self`'s semantic conformance to `RandomAccessCollection`,
  /// expecting its elements to match `expectedContents`.
  ///
  /// - Parameter operationCounts: if supplied, should be an instance that
  ///   tracks operations in copies of `self`.
  /// - Parameter maxSupportedCount: the maximum number of elements that instances of `Self` can
  ///   have.
  ///
  /// - Requires: `self.count >= 2 || self.count >= maxSupportedCount`.
  /// - Complexity: O(N²), where N is `self.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  public func checkRandomAccessCollectionLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents,
    operationCounts: RandomAccessOperationCounts = .init(),
    maxSupportedCount: Int = Int.max
  )
  where ExampleContents.Element == Element
  {
    checkBidirectionalCollectionLaws(
      expecting: expectedContents, maxSupportedCount: maxSupportedCount)
    operationCounts.reset()
    
    XCTAssertEqual(distance(from: startIndex, to: endIndex), count)
    XCTAssertEqual(operationCounts.indexAfter, 0)
    XCTAssertEqual(operationCounts.indexBefore, 0)
    
    XCTAssertEqual(distance(from: endIndex, to: startIndex), -count)
    XCTAssertEqual(operationCounts.indexAfter, 0)
    XCTAssertEqual(operationCounts.indexBefore, 0)

    XCTAssertEqual(index(startIndex, offsetBy: count), endIndex)
    XCTAssertEqual(operationCounts.indexAfter, 0)
    XCTAssertEqual(operationCounts.indexBefore, 0)
    
    XCTAssertEqual(index(endIndex, offsetBy: -count), startIndex)
    XCTAssertEqual(operationCounts.indexAfter, 0)
    XCTAssertEqual(operationCounts.indexBefore, 0)

    XCTAssertEqual(
      index(startIndex, offsetBy: count, limitedBy: endIndex), endIndex)
    XCTAssertEqual(operationCounts.indexAfter, 0)
    XCTAssertEqual(operationCounts.indexBefore, 0)
    
    XCTAssertEqual(
      index(endIndex, offsetBy: -count, limitedBy: startIndex), startIndex)
    XCTAssertEqual(operationCounts.indexAfter, 0)
    XCTAssertEqual(operationCounts.indexBefore, 0)
  }
}

extension MutableCollection where Element: Equatable {
  /// XCTests `self`'s semantic conformance to `MutableCollection`.
  ///
  /// - Requires: `count == distinctContents.count && !self.elementsEqual(distinctContents)`.
  public mutating func checkMutableCollectionLaws<C: Collection>(writing distinctContents: C)
    where C.Element == Element
  {
    precondition(
      count == distinctContents.count, "distinctContents must have the same length as self.")
    precondition(
      !self.elementsEqual(distinctContents),
      "distinctContents must not have the same elements as self")

    for (i, e) in zip(indices, distinctContents) { self[i] = e }
    XCTAssert(self.elementsEqual(distinctContents))
  }
}

// Local Variables:
// fill-column: 100
// End:
