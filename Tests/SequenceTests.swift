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

/// A sequence of Ints with as few assumptions as possible
final class TestSequence: Sequence, IteratorProtocol {
  var x = 0
  let end: Int
  let resurrectMe: Bool
  
  init(end: Int, illegalRessurection: Bool = false) {
    self.end = end
    resurrectMe = illegalRessurection
  }
  
  func next() -> Int? {
    if x == end {
      if resurrectMe { x += 1 }
      return nil
    }
    defer { x += 1 }
    return x
  }
}

class SequenceTests: CheckXCAssertionFailureTestCase {
  func testSuccess() {
    TestSequence(end: 20).checkSequenceLaws(expecting: 0..<20)
    (0..<20).checkSequenceLaws(expecting: 0..<20)
  }

  func testElementMismatch() {
    checkXCAssertionFailure(
      TestSequence(end: 20).checkSequenceLaws(expecting: 1..<21))
  }

  func testMissingElements() {
    checkXCAssertionFailure(
      TestSequence(end: 20).checkSequenceLaws(expecting: 0..<25))
  }

  func testIteratorRessurrection() {
    checkXCAssertionFailure(
      TestSequence(end: 20, illegalRessurection: true).checkSequenceLaws(expecting: 0..<20))
  }
}
