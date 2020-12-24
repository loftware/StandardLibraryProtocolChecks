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
import LoftTest_CheckXCAssertionFailure
import LoftTest_StandardLibraryProtocolChecks

final class BinaryFunctionTests: CheckXCAssertionFailureTestCase {

  func testAssociativity() {
    checkAssociativity(over: 1, 2, 3, operationID: "+", of: +)
    checkAssociativity(over: 1, 2, 3, operationID: "*", of: *)
    
    checkXCAssertionFailure(
      checkAssociativity(over: 1, 2, 3, operationID: "-", of: -),
      messageExcerpt: "- lacks associativity" )
    
    checkXCAssertionFailure(
      checkAssociativity(over: 100, 20, 3, operationID: "/", of: /),
      messageExcerpt: "/ lacks associativity" )
  }
  
  func testCommutativity() {
    checkCommutativity(over: 3, 2, operationID: "+", of: +)
    checkCommutativity(over: 3, 2, operationID: "*", of: *)
    
    checkXCAssertionFailure(
      checkCommutativity(over: 3, 2, operationID: "-", of: -),
      messageExcerpt: "- lacks commutativity" )
    
    checkXCAssertionFailure(
      checkCommutativity(over: 5, 10, operationID: "/", of: /),
      messageExcerpt: "/ lacks commutativity" )
  }
}
