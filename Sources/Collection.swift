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

extension Collection where Element: Equatable {
  /// XCTests `self`'s semantic conformance to `Collection`, expecting its
  /// elements to match `expectedContents`.
  ///
  /// - Complexity: O(N²), where N is `self.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  public func checkCollectionLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents
  ) where ExampleContents.Element == Element {
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
    var remainingCount: Int = count
    var offset: Int = 0
    var expectedIndices = indices
    var sequenceElements = makeIterator()
    var priorIndex: Index? = nil

    // NOTE: if you edit this loop, you probably want to edit the inverse one for
    // checkBidirectionalCollectionLaws (see BidirectionalCollection.swift).
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
    XCTAssert(firstPassElements.elementsEqual(self), "Collection is not multipass.")
  }
}

