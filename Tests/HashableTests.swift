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

//
// MARK: - Hashable
//

extension BrokenFloat {
  enum HashableLaw { case hashValueIsConsistentWithEquality }
}

extension BrokenFloat: Hashable {
  func hash(into sink: inout Hasher) {
    if case .hashable(let broken) = brokenLaw {
      switch broken {
      case .hashValueIsConsistentWithEquality: ObjectIdentifier(self).hash(into: &sink)
      }
    } else {
      value.hash(into: &sink)
    }
  }
}

class HashableTests: CheckXCAssertionFailureTestCase {
  func testIndistinctInstances() {
    0.checkHashableLaws()
    1.checkHashableLaws()
  }
  
  func testDistinctInstances() {
    Box(0).checkHashableLaws(equal: Box(0), Box(0))
    Box(1).checkHashableLaws(equal: Box(1), Box(1))
  }

  /// Shows that testing Hashable also tests Equatable
  func testEquatableFailures() {
    let r = EquatableTests.irreflexiveSamples
    checkXCAssertionFailure(
      r[0].checkHashableLaws(equal: r[1], r[2]), messageExcerpt:  "reflexivity")
    
    let s = EquatableTests.asymmetricSamples
    checkXCAssertionFailure(
      s[0].checkHashableLaws(equal: s[1], s[2]), messageExcerpt:  "symmetry")
    
    let t = EquatableTests.intransitiveSamples
    checkXCAssertionFailure(
      t[0].checkHashableLaws(equal: t[1], t[2]), messageExcerpt:  "transitivity")
  }

  func testHashableFailure() {
    let s = [0, 0, 0].map { BrokenFloat($0, butNot: .hashable(.hashValueIsConsistentWithEquality)) }
    
    s[0].checkEquatableLaws(equal: s[1], s[2])
    
    checkXCAssertionFailure(
      s[0].checkHashableLaws(equal: s[1], s[2]), messageExcerpt:  "distinct hash")
  }
}
