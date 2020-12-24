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
  enum EquatableLaw: String { case equalIsReflexive, equalIsSymmetric, equalIsTransitive }
}

extension BrokenFloat: Equatable {
  static func == (l: BrokenFloat, r: BrokenFloat) -> Bool {
    guard case .equatable(let broken) = l.brokenLaw else { return l.value == r.value }
    switch broken {
    case .equalIsReflexive: return l !== r && l.value == r.value
    case .equalIsSymmetric: return l.value <= r.value
    case .equalIsTransitive: return abs(l.value - r.value) <= 1
    }
  }
}

final class EquatableTests: CheckXCAssertionFailureTestCase {
  static var irreflexiveSamples = [0, 0, 0, 10, 100].map {
    BrokenFloat($0, butNot: .equatable(.equalIsReflexive))
  }
  static var asymmetricSamples = [0, 1, 2, 10, 100].map {
    BrokenFloat($0, butNot: .equatable(.equalIsSymmetric))
  }
  static var intransitiveSamples = [0, 1, 2, 10, 100].map {
    BrokenFloat($0, butNot: .equatable(.equalIsTransitive))
  }
  
  func testIndistinctInstances() {
    0.checkEquatableLaws()
    1.checkEquatableLaws()
  }

  func testDistinctInstances() {
    Box(0).checkEquatableLaws(equal: Box(0), Box(0))
    Box(1).checkEquatableLaws(equal: Box(1), Box(1))
  }

  func testReflexivity() {
    let samples = Self.irreflexiveSamples
    XCTAssertEqual(samples[0], samples[1])
    XCTAssertEqual(samples[1], samples[2])
    
    checkXCAssertionFailure(
      samples[0].checkEquatableLaws(equal: samples[1], samples[2]), messageExcerpt: "reflexivity")
  }

  func testSymmetry() {
    let samples = Self.asymmetricSamples
    XCTAssertEqual(samples[0], samples[1])
    XCTAssertEqual(samples[1], samples[2])
    
    checkXCAssertionFailure(
      samples[0].checkEquatableLaws(equal: samples[1], samples[2]), messageExcerpt: "symmetry")
  }

  func testTransitivity() {
    let samples = Self.intransitiveSamples
    XCTAssertEqual(samples[0], samples[1])
    XCTAssertEqual(samples[1], samples[2])
    
    checkXCAssertionFailure(
      samples[0].checkEquatableLaws(equal: samples[1], samples[2]), messageExcerpt:  "transitivity")
  }
}
