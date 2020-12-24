// Copyright 2020 Dave Abrahams. All Rights Reserved.
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

/// XCTests that `f` is an [associative](https://en.wikipedia.org/wiki/Associative_property)
/// operation over `a0`, `a1`, and `a2`, in case of failure identifying the operation under test as
/// `operationID` if it is non-`nil`.
public func checkAssociativity<T: Equatable>(
  over a0: T, _ a1: T, _ a2: T, operationID: String? = nil, of f: (T, T)->T
) {
    XCTAssertEqual(
      f(f(a0, a1), a2), f(a0, f(a1, a2)),
      "\(operationID ?? "operation") lacks associativity over \(a0), \(a1), and \(a2).")
}
  
/// XCTests that `f` is a [commutative](https://en.wikipedia.org/wiki/Commutative_property)
/// operation over `a0` and `a1`, in case of failure identifying the operation under test as
/// `operationID` if it is non-`nil`.
public func checkCommutativity<Argument, Result: Equatable>(
  over a0: Argument, _ a1: Argument, operationID: String? = nil,
  of f: (Argument, Argument)->Result
) {
    XCTAssertEqual(
      f(a0, a1), f(a1, a0),
      "\(operationID ?? "operation") lacks commutativity over \(a0) and \(a1).")
}
