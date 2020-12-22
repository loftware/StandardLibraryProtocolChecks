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

extension BrokenFloat {
  // There are many laws because for some reason all the comparison operators are separate
  // requirements, even though they can be derived from `<`.
  enum ComparableLaw {    
    case less(LessLaw)
    case lessOrEqual(LessOrEqualLaw)
    case greaterOrEqual(GreaterOrEqualLaw)
    case greater(GreaterLaw)
  }
  enum LessLaw { case equalImpliesFalse, greaterOrEqualImpliesFalse, greaterImpliesFalse }
  enum LessOrEqualLaw { case lessImpliesTrue, equalImpliesTrue, greaterImpliesFalse }
  enum GreaterOrEqualLaw { case lessImpliesFalse, equalImpliesTrue, greaterImpliesTrue }
  enum GreaterLaw { case lessImpliesFalse, lessOrEqualImpliesFalse, equalImpliesFalse }
}

extension BrokenFloat: Comparable {
  static func < (l: BrokenFloat, r: BrokenFloat) -> Bool {
    if case .comparable(.less(let broken)) = l.brokenLaw {
      switch broken {
      case .equalImpliesFalse: if l == r { return true }
      case .greaterOrEqualImpliesFalse: if l >= r { return true }
      case .greaterImpliesFalse: if l > r { return true }
      }
    }
    return l.value < r.value
  }

  static func <= (l: BrokenFloat, r: BrokenFloat) -> Bool {
    if case .comparable(.lessOrEqual(let broken)) = l.brokenLaw {
      switch broken {
      case .lessImpliesTrue: if l < r { return false }
      case .equalImpliesTrue: if l == r { return false }
      case .greaterImpliesFalse: if l > r { return true }
      }
    }
    return l.value <= r.value
  }

  static func >= (l: BrokenFloat, r: BrokenFloat) -> Bool {
    if case .comparable(.greaterOrEqual(let broken)) = l.brokenLaw {
      switch broken {
      case .lessImpliesFalse: if l < r { return true }
      case .equalImpliesTrue: if l == r { return false }
      case .greaterImpliesTrue: if l > r { return false }
      }
    }
    return l.value >= r.value
  }

  static func > (l: BrokenFloat, r: BrokenFloat) -> Bool {
    if case .comparable(.greater(let broken)) = l.brokenLaw {
      switch broken {
      case .lessImpliesFalse: if l < r { return true }
      case .lessOrEqualImpliesFalse: if l <= r { return true }
      case .equalImpliesFalse: if l == r { return true }
      }
    }
    return l.value > r.value
  }
}

class ComparableTests: CheckXCAssertionFailureTestCase {
  func testIndistinctInstances() {
    0.checkComparableLaws(greater: 1, greaterStill: 2)
    (-2).checkComparableLaws(greater: -1, greaterStill: 0)
  }
  
  func testDistinctInstances() {
    let box0 = Box(0), box0a = Box(0), box0b = Box(0)
    let box1 = Box(1), box1a = Box(1), box1b = Box(1)
    let box2 = Box(2)
    let box3 = Box(3)
    box0.checkComparableLaws(equal: box0a, box0b, greater: box1, greaterStill: box2)
    box1.checkComparableLaws(equal: box1a, box1b, greater: box2, greaterStill: box3)
  }

  /// Shows that testing Comparable also tests Equatable
  func testEquatableFailures() {
    let r = EquatableTests.irreflexiveSamples

    checkXCAssertionFailure(
      r[0].checkComparableLaws(equal: r[1], r[2], greater: r[3], greaterStill: r[4]),
      messageExcerpt: "reflexivity")

    let s = EquatableTests.asymmetricSamples
    checkXCAssertionFailure(
      s[0].checkComparableLaws(equal: s[1], s[2], greater: s[3], greaterStill: s[4]),
      messageExcerpt: "symmetry")
    
    let t = EquatableTests.intransitiveSamples
    checkXCAssertionFailure(
      t[0].checkComparableLaws(equal: t[1], t[2], greater: t[3], greaterStill: t[4]),
      messageExcerpt: "transitivity")
  }

  func testComparableFailures() {
    let laws: [BrokenFloat.ComparableLaw] = [
      .less(.equalImpliesFalse), .less(.greaterOrEqualImpliesFalse), .less(.greaterImpliesFalse),
      
      .lessOrEqual(.lessImpliesTrue),
      .lessOrEqual(.equalImpliesTrue),
      .lessOrEqual(.greaterImpliesFalse),
      
      .greaterOrEqual(.lessImpliesFalse),
      .greaterOrEqual(.equalImpliesTrue),
      .greaterOrEqual(.greaterImpliesTrue),
      
      .greater(.lessImpliesFalse), .greater(.lessOrEqualImpliesFalse), .greater(.equalImpliesFalse)
    ]

    for broken in laws {
      let s = [0, 0, 0, 1, 2].map { BrokenFloat($0, butNot: .comparable(broken)) }
      
      s[0].checkEquatableLaws(equal: s[1], s[2])
      checkXCAssertionFailure(
        s[0].checkComparableLaws(equal: s[1], s[2], greater: s[3], greaterStill: s[4]))
    }
  }

  func testSort3() {
    // This is horrifying; we need a next_permutation implementation.
    for zeroPos in 0..<3 {
      for onePos in 0..<3 where onePos != zeroPos {
        for twoPos in 0..<3 where twoPos != zeroPos && twoPos != onePos {
          var a = [0, 0, 0]
          a[onePos] = 1
          a[twoPos] = 2
          let sorted = Int.sort3(a[0], a[1], a[2])
          XCTAssert(sorted == (0, 1, 2))
        }
      }
    }
  }
}
