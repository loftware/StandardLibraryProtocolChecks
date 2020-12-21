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

extension Equatable {
  /// XCTests `Self`'s conformance to `Equatable`, given equivalent instances
  /// `self`, `self1`, and `self2`.
  ///
  /// If `Self` has a distinguishable identity or any remote parts, `self`, `self1`, and `self2`
  /// should not be trivial copies of each other.  In other words, the instances should be as
  /// different as possible internally, while still being equal.  Otherwise, it's fine to pass `nil`
  /// (the default) for `self1` and `self2`.
  public func checkEquatableLaws(equal self1: Self? = nil, _ self2: Self? = nil) {
    let self1 = self1 ?? self
    let self2 = self2 ?? self
    
    XCTAssertEqual(self, self, "Equatable conformance: == lacks reflexivity.")
    XCTAssertEqual(self1, self1, "Equatable conformance: == lacks reflexivity.")
    XCTAssertEqual(self2, self2, "Equatable conformance: == lacks reflexivity.")
    
    XCTAssertEqual(self1, self, "Equatable conformance: == lacks symmetry.")
    XCTAssertEqual(self2, self1, "Equatable conformance: == lacks symmetry.")

    XCTAssertEqual(self, self2, "Equatable conformance: == lacks transitivity.")
  }
}
