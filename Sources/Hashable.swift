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

extension Hashable {
  /// XCTests `Self`'s conformance to `Hashable`, given equivalent instances
  /// `self`, `self1`, and `self2`.
  ///
  /// If `Self` has a distinguishable identity or any remote parts, `self`, `self1`, and `self2`
  /// should not be trivial copies of each other.  In other words, the instances should be as
  /// different as possible internally, while still being equal.  Otherwise, it's fine to pass `nil`
  /// (the default) for `self1` and `self2`.
  public func checkHashableLaws(equal self1: Self? = nil, _ self2: Self? = nil) {
    checkEquatableLaws(equal: self1, self2)
    let self1 = self1 ?? self
    let self2 = self2 ?? self
    let message = "Equal instances have distinct hash values"
    XCTAssertEqual(self.hashValue, self1.hashValue, message)
    XCTAssertEqual(self.hashValue, self2.hashValue, message)
  }
}

