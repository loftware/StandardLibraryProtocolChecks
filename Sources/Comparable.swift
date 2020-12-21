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

extension Comparable {
  /// XCTests that `self` obeys all comparable laws with respect to an equivalent instance
  /// `self1`.
  ///
  /// If `Self` has a distinguishable identity or any remote parts, `self` and `self1` should
  /// not be trivial copies of each other.  In other words, the instances should be as different as
  /// possible internally, while still being equal.  Otherwise, it's fine to pass `nil` (the
  /// default) for `self1`.
  ///
  /// - Precondition: `self == (self1 ?? self)`
  private func checkComparableUnordered(equal self1: Self? = nil) {
    let self1 = self1 ?? self
    // Comparable still has distinct requirements for <,>,<=,>= so we need to check them all :(
    // Not Using XCTAssertLessThanOrEqual et al. because we don't want to be reliant on them calling
    // the operators literally; there are other ways they could be implemented.
    XCTAssertFalse(self < self1)
    XCTAssertFalse(self > self1)
    XCTAssertFalse(self1 < self)
    XCTAssertFalse(self1 > self)
    XCTAssert(self <= self1)
    XCTAssert(self >= self1)
    XCTAssert(self1 <= self)
    XCTAssert(self1 >= self)
  }

  /// XCTests that `self` obeys all comparable laws with respect to a greater value `greater`.
  private func checkComparableOrdering(greater: Self) {
    XCTAssert(self < greater, "Possible mis-test; \(self) ≮ \(greater).")
    // Comparable still has distinct requirements for <,>,<=,>= so we need to check them all :(
    
    // Not Using XCTAssertLessThanOrEqual et al. because we don't want to be reliant on them calling
    // the operators literally; there are other ways they could be implemented.
    XCTAssert(self <= greater)
    XCTAssertNotEqual(self, greater)
    XCTAssertFalse(self >= greater)
    XCTAssertFalse(self > greater)

    XCTAssertFalse(greater < self)
    XCTAssertFalse(greater <= self)
    XCTAssert(greater >= self)
    XCTAssert(greater > self)
  }
  
  /// XCTests `Self`'s conformance to `Comparable`.
  ///
  /// If `Self` has a distinguishable identity or any remote parts, `self`, `self1`, and `self2`
  /// should be equivalent, but should not be trivial copies of each other.  In other words, the
  /// instances should be as different as possible internally, while still being equal.  Otherwise,
  /// it's fine to pass `nil` (the default) for `self1` and `self2`.
  ///
  /// If distinct values for `greater` or `greaterStill` are unavailable (e.g. when `Self` only has
  /// one or two values), the caller may pass `nil` values. Callers are encouraged to pass non-`nil`
  /// values whenever they are available, because they enable more checks.
  ///
  /// - Precondition: `self == (self1 ?? self) && self1 == (self2 ?? self)`.
  /// - Precondition: if `greaterStill != nil`, `greater != nil`.
  /// - Precondition: if `greater != nil`, `self < greater!`.
  /// - Precondition: if `greaterStill != nil`, `greater! < greaterStill!`.
  public func checkComparableLaws(
    equal self1: Self? = nil, _ self2: Self? = nil, greater: Self?, greaterStill: Self?
  ) {
    precondition(
      greater != nil || greaterStill == nil, "`greaterStill` should be `nil` when `greater` is.")

    checkEquatableLaws(equal: self1, self2)
    
    self.checkComparableUnordered(equal: self)
    self.checkComparableUnordered(equal: self1)
    self.checkComparableUnordered(equal: self2)
    (self1 ?? self).checkComparableUnordered(equal: self2)
    greater?.checkComparableUnordered()
    greaterStill?.checkComparableUnordered()

    if let greater = greater {
      self.checkComparableOrdering(greater: greater)
      if let greaterStill = greaterStill {
        greater.checkComparableOrdering(greater: greaterStill)
        // Transitivity
        self.checkComparableOrdering(greater: greaterStill)
      }
    }
  }

  /// Given three unequal instances, returns them in increasing order, relying only on <.
  ///
  /// This function can be useful for checking comparable conformance in conditions where you know
  /// you have unequal instances, but can't control the ordering.
  ///
  ///     let (min, mid, max) = X.sort3(X(a), X(b), X(c))
  ///     min.checkComparableLaws(greater: mid, greaterStill: max)
  ///
  public static func sort3(_ a: Self, _ b: Self, _ c: Self) -> (Self, Self, Self) {
    precondition(a != b)
    precondition(a != c)
    precondition(b != c)
    
    let min = a < b
      ? a < c ? a : c
      : b < c ? b : c
    
    let max = a < b
      ? b < c ? c : b
      : a < c ? c : a
    
    let mid = a < b
      ? b < c
          ? b 
          : a < c ? c : a
      : a < c 
	        ? a
          : b < c ? c : b

    return (min, mid, max)
  }
}
