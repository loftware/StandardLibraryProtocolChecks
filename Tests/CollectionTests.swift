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

class CollectionTests: CheckXCAssertionFailureTestCase {
  func testSuccess() {
    FlawedCollection(brokenLaw: nil).checkCollectionLaws(expecting: 0..<20)
    (0..<20).checkCollectionLaws(expecting: 0..<20)
  }

  func testFailSequenceElementsMatch() {
    checkXCAssertionFailure(
      FlawedCollection(brokenLaw: .sequenceElementsMatch)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "iterator/subscript access mismatch")
  }

  func testFailIteratorDoesNotResurrect() {
    checkXCAssertionFailure(
      FlawedCollection(brokenLaw: .iteratorDoesNotResurrect)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "Exhausted iterator expected to return nil from next")
  }

  func testFailIndicesPropertyElementsMatch() {
    checkXCAssertionFailure(
      FlawedCollection(brokenLaw: .indicesPropertyElementsMatch)
        .checkCollectionLaws(expecting: 0..<20),
        messageExcerpt: "elements of indices property don't match index(after:)")
  }

  func testFailIndicesPropertySameLengthAsSelf() {
    checkXCAssertionFailure(
      FlawedCollection(brokenLaw: .indicesPropertySameLengthAsSelf)
        .checkCollectionLaws(expecting: 0..<20),
        messageExcerpt: "indices property has too many elements")
  }

  func testFailIndicesAreStrictlyIncreasing() {
    checkXCAssertionFailure(
      FlawedCollection(brokenLaw: .indicesAreStrictlyIncreasing)
        .checkCollectionLaws(expecting: 0..<20),
        messageExcerpt: "indices are not strictly increasing")
  }
  
  func testFailForwardIndexOffsetByWorks() {
    checkXCAssertionFailure(
      FlawedCollection(brokenLaw: .forwardIndexOffsetByWorks)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:) offset >= 0, unexpected result")
  }
  
  func testFailForwardIndexOffsetByLimitedByEndIndexMatchesIndexOffsetBy() {
    checkXCAssertionFailure(
      FlawedCollection(
        brokenLaw: .indexOffsetByLimitedByEndIndexMatchesIndexOffsetBy)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:limitedBy: endIndex) offset >= 0, limit not exceeded")
  }
  
  func testFailForwardIndexOffsetByLimitedByRespectsLimit() {
    checkXCAssertionFailure(
      FlawedCollection(
        brokenLaw: .forwardIndexOffsetByLimitedByRespectsLimit)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:limitedBy:) offset > 0, limit not respected")
  }
  
  func testFailForwardDistanceWorks() {
    checkXCAssertionFailure(
      FlawedCollection(
        brokenLaw: .forwardDistanceWorks).checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "distance(from: i, to: j), i < j unexpected result")
  }
  
  func testFailIsMultipass() {
    checkXCAssertionFailure(
      FlawedCollection(
        brokenLaw: .isMultipass).checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "multipass")
  }
}
