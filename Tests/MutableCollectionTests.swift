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

struct FlawedMutableCollection: MutableCollection {
  enum Law {
    case
      subscriptSetPersistsNewValue,
      subscriptSetDoesNotMutateOtherElements,
      subscriptSetDoesNotChangeCount,
      subscriptModifyExposesOldValue,
      subscriptModifyPersistsNewValue,
      subscriptModifyDoesNotMutateOtherElements,
      subscriptModifyDoesNotChangeCount
  }

  typealias Storage = [Int]
  typealias Index = Storage.Index
  var storage = Array(0..<20)
  let brokenLaw: Law?

  var startIndex: Index { storage.startIndex }
  var endIndex: Index { storage.endIndex }
  func index(after i: Index) -> Index { storage.index(after: i) }
  
  subscript(i: Index) -> Int {
    get { storage[i] }
    set {
      if brokenLaw == .subscriptSetDoesNotMutateOtherElements {
        storage[(i + 10) % 20] += 1
      }
      storage[i] = newValue + (brokenLaw == .subscriptSetPersistsNewValue ? 1 : 0)
      if brokenLaw == .subscriptSetDoesNotChangeCount { storage.append(0) }
    }
    _modify {
      var io = storage[i] + (brokenLaw == .subscriptModifyExposesOldValue ? 1 : 0)
      if brokenLaw == .subscriptModifyDoesNotMutateOtherElements {
        storage[(i + 10) % 20] += 1
      }
      
      yield &io
      
      storage[i] = io + (brokenLaw == .subscriptModifyPersistsNewValue ? 1 : 0)
      if brokenLaw == .subscriptModifyDoesNotChangeCount { storage.append(0) }
    }
  }
}

class MutableCollectionTests: CheckXCAssertionFailureTestCase {
  func testSuccess() {
    var subject = FlawedMutableCollection(brokenLaw: nil)
    subject.checkMutableCollectionLaws(expecting: 0..<20, writing: 20..<40)
  }

  func testFailSubscriptSetPersistsNewValue() {
    var subject = FlawedMutableCollection(brokenLaw: .subscriptSetPersistsNewValue)
    checkXCAssertionFailure(
      subject.checkMutableCollectionLaws(expecting: 0..<20, writing: 20..<40),
      messageExcerpt: "subscript set did not persist")
  }

  func testFailSubscriptSetDoesNotMutateOtherElements() {
    var subject = FlawedMutableCollection(brokenLaw: .subscriptSetDoesNotMutateOtherElements)
    checkXCAssertionFailure(
      subject.checkMutableCollectionLaws(expecting: 0..<20, writing: 20..<40),
      messageExcerpt: "subscript set mutated")
  }

  func testFailSubscriptSetDoesNotChangeCount() {
    var subject = FlawedMutableCollection(brokenLaw: .subscriptSetDoesNotChangeCount)
    checkXCAssertionFailure(
      subject.checkMutableCollectionLaws(expecting: 0..<20, writing: 20..<40),
      messageExcerpt: "changed count")
  }

  func testFailSubscriptModifyExposesOldValue() {
    var subject = FlawedMutableCollection(brokenLaw: .subscriptModifyExposesOldValue)
    checkXCAssertionFailure(
      subject.checkMutableCollectionLaws(expecting: 0..<20, writing: 20..<40),
      messageExcerpt: "subscript modify did not expose the old element value")
  }

  func testFailSubscriptModifyPersistsNewValue() {
    var subject = FlawedMutableCollection(brokenLaw: .subscriptModifyPersistsNewValue)
    checkXCAssertionFailure(
      subject.checkMutableCollectionLaws(expecting: 0..<20, writing: 20..<40),
      messageExcerpt: "subscript modify did not persist")
  }

  func testFailSubscriptModifyDoesNotMutateOtherElements() {
    var subject = FlawedMutableCollection(brokenLaw: .subscriptModifyDoesNotMutateOtherElements)
    checkXCAssertionFailure(
      subject.checkMutableCollectionLaws(expecting: 0..<20, writing: 20..<40),
      messageExcerpt: "subscript modify mutated")
  }

  func testFailSubscriptModifyDoesNotChangeCount() {
    var subject = FlawedMutableCollection(brokenLaw: .subscriptModifyDoesNotChangeCount)
    checkXCAssertionFailure(
      subject.checkMutableCollectionLaws(expecting: 0..<20, writing: 20..<40),
      messageExcerpt: "changed count")
  }
}
