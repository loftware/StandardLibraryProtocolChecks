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

class TestTinyCollections: CheckXCAssertionFailureTestCase {
  func testEmptyCollectionSuccess() {
    EmptyCollection<Int>().checkBidirectionalCollectionLaws(expecting: [])
  }

  func testEmptyCollectionFail() {
    checkXCAssertionFailure(
      EmptyCollection<Int>().checkBidirectionalCollectionLaws(expecting: 2...2))
  }

  func testCollectionOfOneSuccess() {
    CollectionOfOne(42).checkBidirectionalCollectionLaws(expecting: 42...42)
  }

  func testCollectionOfOneFailExpectedTooLong() {
    checkXCAssertionFailure(
      CollectionOfOne(42).checkBidirectionalCollectionLaws(expecting: 2...4),
      messageExcerpt: "Expected tail elements")
  }

  func testCollectionOfOneFailExpectedTooShort() {
    checkXCAssertionFailure(
      CollectionOfOne(42).checkBidirectionalCollectionLaws(expecting: EmptyCollection()),
      messageExcerpt: "More elements than expected found")
  }
}

