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

/// A Really simple adapter over any `Base` that presents the same elements.
struct TrivialAdapter<Base: RandomAccessCollection>: RandomAccessCollection {
  var base: Base
  typealias Index = Base.Index
  var startIndex: Base.Index { base.startIndex }
  var endIndex: Base.Index { base.endIndex }

  subscript(i: Index) -> Base.Element { base[i] }

  func index(after i: Index) -> Index { return base.index(after: i) }
  func index(before i: Index) -> Index { return base.index(before: i) }
}

extension TrivialAdapter: RandomAccessCollectionAdapter {}

class TestExample: CheckXCAssertionFailureTestCase {
  func testLaws() {
    // Create a collection with operation counting.
    let counter = RandomAccessOperationCounter(0..<20)
    
    // Now adapt it with our adapter
    let testSubject = TrivialAdapter(base: counter)
    
    checkXCAssertionFailure(
      testSubject.checkRandomAccessCollectionLaws(
        expecting: 0..<20, operationCounts: counter.operationCounts),
      messageExcerpt: "O(1)")
  }
}

// Local Variables:
// fill-column: 100
// End:
