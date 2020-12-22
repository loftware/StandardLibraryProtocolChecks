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

struct FlawedAdapter<Base: RandomAccessCollection> {
  enum Law {
    case
      // RandomAccessCollection laws
      forwardDistanceIsO1,
      reverseDistanceIsO1,
      forwardIndexOffsetByIsO1,
      reverseIndexOffsetByIsO1,
      forwardIndexOffsetByLimitedByIsO1,
      reverseIndexOffsetByLimitedByIsO1
  }

  var base: Base
  let brokenLaw: Law?
}

extension FlawedAdapter: Collection {
  typealias Index = Base.Index
  var startIndex: Base.Index { base.startIndex }
  var endIndex: Base.Index { base.endIndex }

  subscript(i: Index) -> Base.Element { base[i] }

  func index(after i: Index) -> Index { return base.index(after: i) }
  func index(before i: Index) -> Index { return base.index(before: i) }

  func index(_ i: Index, offsetBy n: Int) -> Index {
    var i1 = i
    if n > 0 && brokenLaw == .forwardIndexOffsetByIsO1 {
      for _ in 0..<n { formIndex(after: &i1) }
      return i1
    }
    if n < 0 && brokenLaw == .reverseIndexOffsetByIsO1 {
      for _ in n..<0 { formIndex(before: &i1) }
      return i1
    }
    return base.index(i, offsetBy: n)
  }

  func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    var i1 = i
    if n > 0 && brokenLaw == .forwardIndexOffsetByLimitedByIsO1 {
      for _ in 0..<n {
        if i1 == limit { return nil }
        formIndex(after: &i1)
      }
      return i1
    }
    if n < 0 && brokenLaw == .reverseIndexOffsetByLimitedByIsO1 {
      for _ in n..<0 {
        if i1 == limit { return nil }
        formIndex(before: &i1)
      }
      return i1
    }
    return base.index(i, offsetBy: n, limitedBy: limit)
  }

  func distance(from i: Index, to j: Index) -> Int {
    if i < j {
      if brokenLaw == .forwardDistanceIsO1 {
        var i1 = i, n = 0
        while i1 != j { formIndex(after: &i1); n += 1 }
        return n
      }
    }
    else {
      if brokenLaw == .reverseDistanceIsO1 {
        var j1 = j, n = 0
        while j1 != i { formIndex(after: &j1); n -= 1 }
        return n
      }
    }
    return base.distance(from: i, to: j)
  }
}

extension FlawedAdapter: RandomAccessCollection, RandomAccessCollectionAdapter {}

class RandomAccessCollectionTests: CheckXCAssertionFailureTestCase {
  func makeBase() -> RandomAccessOperationCounter<Range<Int>> {
    RandomAccessOperationCounter(0..<20)
  }
  
  func testSuccess() {
    let base = makeBase()
    FlawedAdapter(base: base, brokenLaw: nil)
      .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts)
  }

  func testFailForwardDistanceIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      FlawedAdapter(base: base, brokenLaw: .forwardDistanceIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "distance(from: i, to: j) i <= j is not O(1)")
  }

  func testFailReverseDistanceIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      FlawedAdapter(base: base, brokenLaw:  .reverseDistanceIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "distance(from: i, to: j) j <= i is not O(1)")
  }

  func testFailForwardIndexOffsetByIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      FlawedAdapter(base: base, brokenLaw: .forwardIndexOffsetByIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "index(:offsetBy: i) i >= 0 is not O(1)")
  }

  func testFailReverseIndexOffsetByIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      FlawedAdapter(base: base, brokenLaw:  .reverseIndexOffsetByIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "index(:offsetBy: i) i <= 0 is not O(1)")
  }
  
  func testFailForwardIndexOffsetByLimitedByIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      FlawedAdapter(base: base, brokenLaw: .forwardIndexOffsetByLimitedByIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "index(:offsetBy: i, limitedBy:) i >= 0 is not O(1)")
  }

  func testFailReverseIndexOffsetByLimitedByIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      FlawedAdapter(base: base, brokenLaw:  .reverseIndexOffsetByLimitedByIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "index(:offsetBy: i, limitedBy:) i <= 0 is not O(1)")
  }
}
