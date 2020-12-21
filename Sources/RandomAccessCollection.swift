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
  ///
  /// - Complexity: O(N²), where N is `self.count`.
  public func checkRandomAccessCollectionLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents,
    operationCounts: RandomAccessOperationCounts
  )
  where ExampleContents.Element == Element
  {
    checkBidirectionalCollectionLaws(expecting: expectedContents)
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
