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
import LoftTest_CheckXCAssertionFailure
import LoftTest_StandardLibraryProtocolChecks

/// A Really simple adapter over any `Base` that presents the same elements.
struct TrivialAdapter<Base: RandomAccessCollection>: RandomAccessCollection {
  var base: Base
  typealias Index = Base.Index
  var startIndex: Base.Index { base.startIndex }
  var endIndex: Base.Index { base.endIndex }

  subscript(i: Index) -> Base.Element { base[i] }

  func index(after i: Index) -> Index { return base.index(after: i) }
  func index(before i: Index) -> Index { return base.index(before: i) }
}

extension TrivialAdapter: RandomAccessCollectionAdapter {}

extension LazyMapCollection: RandomAccessCollectionAdapter
  where Base: RandomAccessCollection {}

// Declare its conformance to `RandomAccessCollectionAdapter`
extension ReversedCollection: RandomAccessCollectionAdapter
  where Base: RandomAccessCollection {}

class TestExample: CheckXCAssertionFailureTestCase {
  func testLaws() {
    // Create a collection with operation counting.
    let counter = RandomAccessOperationCounter(0..<20)
    
    // Now adapt it with our adapter
    let testSubject = TrivialAdapter(base: counter)
    
    checkXCAssertionFailure(
      testSubject.checkRandomAccessCollectionLaws(
        expecting: 0..<20, operationCounts: counter.operationCounts),
      messageExcerpt: "O(1)")
  }

  func testLazyMapCollection() {
    let counter = RandomAccessOperationCounter(0..<20)
    counter.lazy.map { $0 + 1 }.checkRandomAccessCollectionLaws(
      expecting: 1..<21, operationCounts: counter.operationCounts)
  }

  func testReversedCollection() {
    // Adapt a special base collection called `RandomAccessOperationCounter`
    let base = RandomAccessOperationCounter(0..<20)
    let adapter: ReversedCollection = base.reversed()

    // Pass the base collection along to the adapter's `checkRandomAccessCollectionLaws` method:
    let expectedElements = (0..<20).map { 19 - $0 }
    adapter.checkRandomAccessCollectionLaws(
      expecting: expectedElements,
      operationCounts: base.operationCounts)
  }
  
  func testHashableInts() {
    let examples = [Int.min, -2, -1, 0, 1, 2, Int.max]
    for i in examples {
      i.checkHashableLaws()
    }
  }

  func testHashableArrays() {
    let a = Array(0..<10)
    var b = Array(0..<10)
    b.reserveCapacity(a.capacity * 2)
    var c = b
    c.reserveCapacity(b.capacity * 2)
    a.checkHashableLaws(equal: b, c)
  }

  
}

// Local Variables:
// fill-column: 100
// End:
