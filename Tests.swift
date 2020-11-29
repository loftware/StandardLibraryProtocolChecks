import XCTest
import LoftTest_CheckXCAssertionFailure
import LoftTest_StandardLibraryProtocolChecks

/// A reference-semantic wrapper for an instance of type `T`.
///
/// This allows us to create instances that are distinguishable but otherwise
/// identical.
final class Box<Content> {
  var content: Content
  init(_ content: Content) { self.content = content }
}

extension Box: Equatable where Content: Equatable {
  static func == (l: Box, r: Box) -> Bool {
    l.content == r.content
  }
}

extension Box: Hashable where Content: Hashable {
  func hash(into sink: inout Hasher) {
    content.hash(into: &sink)
  }
}

extension Box: Comparable where Content: Comparable {
  class func < (l: Box, r: Box) -> Bool {
    l.content < r.content
  }
}



class EquatableTests: CheckXCAssertionFailureTestCase {
  func testValueType() {
    0.checkEquatableSemantics()
    1.checkEquatableSemantics()
  }

  func testReferenceType() {
    Box(0).checkEquatableSemantics(equal: Box(0), Box(0))
    Box(1).checkEquatableSemantics(equal: Box(1), Box(1))
  }

  private final class Flawed: Equatable {
    let value: Float
    let flaw: Flaw

    init(_ value: Float, flaw: Flaw) { (self.value, self.flaw) = (value, flaw) }
    
    enum Flaw {
      case reflexivity, symmetry, transitivity
    }
    
    class func == (l: Flawed, r: Flawed) -> Bool {
      switch l.flaw {
      case .reflexivity: return l !== r && l.value == r.value
      case .symmetry: return l.value <= r.value
      case .transitivity: return abs(l.value - r.value) <= 1
      }
    }
  }
  
  func testReflexivity() {
    checkXCAssertionFailure(
      Flawed(0, flaw: .reflexivity).checkEquatableSemantics(
        equal: Flawed(0, flaw: .reflexivity),
        Flawed(0, flaw: .reflexivity)), "reflexivity")
  }

  func testSymmetry() {
    checkXCAssertionFailure(
      Flawed(0, flaw: .symmetry).checkEquatableSemantics(
        equal: Flawed(1, flaw: .symmetry),
        Flawed(2, flaw: .symmetry)), "symmetry")
  }

  func testTransitivity() {
    checkXCAssertionFailure(
      Flawed(0, flaw: .transitivity).checkEquatableSemantics(
        equal: Flawed(1, flaw: .transitivity),
        Flawed(2, flaw: .transitivity)), "transitivity")
  }
}
