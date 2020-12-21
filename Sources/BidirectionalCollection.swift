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

extension BidirectionalCollection where Element: Equatable {
  /// XCTests `self`'s semantic conformance to `BidirectionalCollection`,
  /// expecting its elements to match `expectedContents`.
  ///
  /// - Complexity: O(N²), where N is `self.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  public func checkBidirectionalCollectionLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents) where ExampleContents.Element == Element
  {
    checkCollectionLaws(expecting: expectedContents)
    
    if Self.self != Indices.self {
      indices.checkBidirectionalCollectionLaws(expecting: indices)
    }
    if Self.self != SubSequence.self {
      self[...].checkBidirectionalCollectionLaws(expecting: expectedContents)
    }

    var i = endIndex
    var remainingCount: Int = count
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
