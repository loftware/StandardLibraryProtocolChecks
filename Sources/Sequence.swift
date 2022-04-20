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

// ************************************************************************************************
// Checking sequence/collection semantics.  Note that these checks cannot see any declarations that
// happen to shadow the protocol requirements. Those shadows have to be tested separately, for
// concrete types (i.e. without using generics or protocol extensions).

extension Sequence {
  /// XCTests `self`'s semantic conformance to `Sequence`, expecting its
  /// elements to match `expectedContents`.
  ///
  /// - Complexity: O(N), where N is `expectedContents.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  public func checkSequenceLaws<
    ExampleContents: Collection>(expecting expectedContents: ExampleContents)
    where ExampleContents.Element == Element, Element: Equatable
  {
    checkSequenceLaws(expecting: expectedContents, areEquivalent: ==)
  }

  /// XCTests `self`'s semantic conformance to `Sequence`, expecting its
  /// elements to match `expectedContents` according to `areEquivalent`.
  ///
  /// - Complexity: O(N), where N is `expectedContents.count`.
  /// - Note: the fact that a call to this method compiles verifies static
  ///   conformance.
  /// - Precondition: `areEquivalent` is an equivalence relation.
  public func checkSequenceLaws<ExampleContents: Collection>(
    expecting expectedContents: ExampleContents,
    areEquivalent: (Element, Element)->Bool
  )
    where ExampleContents.Element == Element
  {
    var i = self.makeIterator()
    var remainder = expectedContents[...]
    while let x = i.next() {
      if let e = remainder.popFirst() {
        XCTAssert(
          areEquivalent(e, x), "\(e) != \(x): Sequence contents don't match expectations.")
      }
      else {
        XCTFail("More elements than expected found.")
      }
    }
    XCTAssert(
      remainder.isEmpty,
      "Expected tail elements \(Array(remainder).suffix(10)) not present in Sequence.")
    XCTAssertNil(
      i.next(),
      "Exhausted iterator expected to return nil from next() in perpetuity.")
  }
}
