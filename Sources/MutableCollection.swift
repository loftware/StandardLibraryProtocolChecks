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


extension MutableCollection {
  /// XCTests `self`'s semantic conformance to `MutableCollection`.
  ///
  /// - Precondition: `count == distinctContents.count`
  /// - Precondition: `zip(self, distinctContents).allSatisfy { $0 != $1 }`
  public mutating func checkMutableCollectionLaws<C0: Collection, C1: Collection>(
    expecting expectedContents: C0, writing distinctContents: C1
  )
    where C0.Element == Element, C1.Element == Element, Element: Equatable
  {
    checkMutableCollectionLaws(
      expecting: expectedContents, writing: distinctContents, areEquivalent: ==)
  }

  /// XCTests `self`'s semantic conformance to `MutableCollection`, checking
  /// element equivalence with `areEquivalent`.
  ///
  /// - Precondition: `count == distinctContents.count`
  /// - Precondition: `zip(self, distinctContents).allSatisfy { !areEquivalent($0,
  /// $1) }`
  /// - Precondition: `areEquivalent` is an equivalence relation.
  public mutating func checkMutableCollectionLaws<C0: Collection, C1: Collection>(
    expecting expectedContents: C0, writing distinctContents: C1,
    areEquivalent: (Element, Element)->Bool
  )
    where C0.Element == Element, C1.Element == Element
  {
    XCTAssertEqual(
      count, distinctContents.count, "distinctContents must have the same length as self.")
    XCTAssert(
      zip(expectedContents, distinctContents).allSatisfy { !areEquivalent($0, $1) },
      "corresponding elements of self and distinctContents must be unequal.")

    checkCollectionLaws(expecting: expectedContents, areEquivalent: areEquivalent)

    let originalEndIndex = endIndex
    let originalContents = Array(self)
    let myIndices = Array(indices)

    // Forward pass testing subscript set
    for (i, (j, k)) in zip(myIndices, zip(distinctContents.indices, originalContents.indices)) {
      self[i] = distinctContents[j]
      XCTAssert(
        areEquivalent(self[i], distinctContents[j]),
        "subscript set did not persist the new value.")
      XCTAssert(
        self[..<i].dropLast()
          .elementsEqual(distinctContents[..<j].dropLast(), by: areEquivalent),
        "subscript set mutated earlier element.")
      XCTAssert(
        self[i...].dropFirst()
          .elementsEqual(originalContents[k...].dropFirst(), by: areEquivalent),
        "subscript set mutated later element or changed count.")
    }

    // Backward pass testing subscript modify
    for (i, (j, k)) in zip(
          myIndices.reversed(),
          zip(distinctContents.indices.reversed(), originalContents.indices.reversed())) {

      func modify(_ e: inout Element, writing x: Element) {
        XCTAssert(
          areEquivalent(e, distinctContents[j]),
          "subscript modify did not expose the old element value for mutation.")
        e = x
      }
      
      modify(&self[i], writing: originalContents[k])
      
      XCTAssert(
        areEquivalent(self[i], originalContents[k]),
        "subscript modify did not persist the new value.")
      XCTAssert(
        self[..<i].dropLast()
          .elementsEqual(distinctContents[..<j].dropLast(), by: areEquivalent),
        "subscript modify mutated earlier element.")
      XCTAssert(
        self[i...].dropFirst()
          .elementsEqual(originalContents[k...].dropFirst(), by: areEquivalent),
        "subscript modify mutated later element or changed count.")
    }
    
    if Self.self != SubSequence.self {
      self[..<originalEndIndex]
        .checkMutableCollectionLaws(
          expecting: expectedContents, writing: distinctContents, areEquivalent: areEquivalent)
    }
  }
}
