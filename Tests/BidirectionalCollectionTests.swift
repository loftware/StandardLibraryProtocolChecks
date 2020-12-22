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

class BidirectionalCollectionTests: CheckXCAssertionFailureTestCase {
  func testSuccess() {
    FlawedCollection(brokenLaw: nil).checkBidirectionalCollectionLaws(expecting: 0..<20)
    (0..<20).checkBidirectionalCollectionLaws(expecting: 0..<20)
  }

  func testFailIndexBeforeUndoesIndexAfter() {
    checkXCAssertionFailure(
      FlawedCollection(brokenLaw: .indexBeforeUndoesIndexAfter)
        .checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(after:) does not undo index(before:)")
  }

  func testFailReverseIndexOffsetByWorks() {
    checkXCAssertionFailure(
      FlawedCollection(brokenLaw: .reverseIndexOffsetByWorks)
        .checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:) offset <= 0, unexpected result")
  }
  
  func testFailReverseIndexOffsetByLimitedByEndIndexMatchesIndexOffsetBy() {
    checkXCAssertionFailure(
      FlawedCollection(
        brokenLaw: .indexOffsetByLimitedByStartIndexMatchesIndexOffsetBy)
        .checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:limitedBy: startIndex) offset <= 0, limit not exceeded")
  }
  
  func testFailReverseIndexOffsetByLimitedByRespectsLimit() {
    checkXCAssertionFailure(
      FlawedCollection(
        brokenLaw: .reverseIndexOffsetByLimitedByRespectsLimit)
        .checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:limitedBy:) offset < 0, limit not respected")
  }
  
  func testFailReverseDistanceWorks() {
    checkXCAssertionFailure(
      FlawedCollection(
        brokenLaw: .reverseDistanceWorks).checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "distance(from: i, to: j), j < i unexpected result")
  }
}
