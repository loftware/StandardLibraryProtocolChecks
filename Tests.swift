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

final class Flawed {
  let value: Float
  let flaw: Flaw

  init(_ value: Float, flaw: Flaw) { (self.value, self.flaw) = (value, flaw) }
  
  enum Flaw {
    case equatableReflexivity, equatableSymmetry, equatableTransitivity
    case hashableEquatableConsistency
  }
}

extension Flawed: Equatable {
  static func == (l: Flawed, r: Flawed) -> Bool {
    l.flaw == .equatableReflexivity ? l !== r && l.value == r.value
      : l.flaw == .equatableSymmetry ? l.value <= r.value
      : l.flaw == .equatableTransitivity ? abs(l.value - r.value) <= 1
      : l.value == r.value
  }
}

extension Flawed: Hashable {
  func hash(into sink: inout Hasher) {
    if flaw == .hashableEquatableConsistency {
      ObjectIdentifier(self).hash(into: &sink)
    }
    else {
      value.hash(into: &sink)
    }
  }
}

final class EquatableTests: CheckXCAssertionFailureTestCase {
  static var irreflexiveSamples = [0, 0, 0].map { Flawed($0, flaw: .equatableReflexivity) }
  static var asymmetricSamples = [0, 1, 2].map { Flawed($0, flaw: .equatableSymmetry) }
  static var intransitiveSamples = [0, 1, 2].map { Flawed($0, flaw: .equatableTransitivity) }
  
  func testIndistinctInstances() {
    0.checkEquatableSemantics()
    1.checkEquatableSemantics()
  }

  func testDistinctInstances() {
    Box(0).checkEquatableSemantics(equal: Box(0), Box(0))
    Box(1).checkEquatableSemantics(equal: Box(1), Box(1))
  }

  func testReflexivity() {
    let samples = Self.irreflexiveSamples
    XCTAssertEqual(samples[0], samples[1])
    XCTAssertEqual(samples[1], samples[2])
    
    checkXCAssertionFailure(
      samples[0].checkEquatableSemantics(equal: samples[1], samples[2]), "reflexivity")
  }

  func testSymmetry() {
    let samples = Self.asymmetricSamples
    XCTAssertEqual(samples[0], samples[1])
    XCTAssertEqual(samples[1], samples[2])
    
    checkXCAssertionFailure(
      samples[0].checkEquatableSemantics(equal: samples[1], samples[2]), "symmetry")
  }

  func testTransitivity() {
    let samples = Self.intransitiveSamples
    XCTAssertEqual(samples[0], samples[1])
    XCTAssertEqual(samples[1], samples[2])
    
    checkXCAssertionFailure(
      samples[0].checkEquatableSemantics(equal: samples[1], samples[2]), "transitivity")
  }
}

class HashableTests: CheckXCAssertionFailureTestCase {
  func testIndistinctInstances() {
    0.checkHashableSemantics()
    1.checkHashableSemantics()
  }
  
  func testDistinctInstances() {
    Box(0).checkHashableSemantics(equal: Box(0), Box(0))
    Box(1).checkHashableSemantics(equal: Box(1), Box(1))
  }

  func testEquatableFailures() {
    let r = EquatableTests.irreflexiveSamples
    checkXCAssertionFailure(r[0].checkHashableSemantics(equal: r[1], r[2]), "reflexivity")
    
    let s = EquatableTests.asymmetricSamples
    checkXCAssertionFailure(s[0].checkHashableSemantics(equal: s[1], s[2]), "symmetry")
    
    let t = EquatableTests.intransitiveSamples
    checkXCAssertionFailure(t[0].checkHashableSemantics(equal: t[1], t[2]), "transitivity")
  }

  func testHashableFailure() {
    let s = [0, 0, 0].map { Flawed($0, flaw: .hashableEquatableConsistency) }
    
    s[0].checkEquatableSemantics(equal: s[1], s[2])
    
    checkXCAssertionFailure(
      s[0].checkHashableSemantics(equal: s[1], s[2]), "distinct hash")
  }
}

// Local Variables:
// fill-column: 100
// End:
