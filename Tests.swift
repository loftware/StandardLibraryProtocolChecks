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

/// A type that selectively breaks one law of regular types.
final class BrokenFloat {
  enum Law {
    case equatable(EquatableLaw), hashable(HashableLaw), comparable(ComparableLaw)
  }
  
  let value: Float  
  let brokenLaw: Law

  init(_ value: Float, butNot brokenLaw: Law) {
    self.value = value
    self.brokenLaw = brokenLaw
  }
  
}

//
// - MARK: Equatable
//

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

//
// - MARK: Hashable
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
    0.checkHashableSemantics()
    1.checkHashableSemantics()
  }
  
  func testDistinctInstances() {
    Box(0).checkHashableSemantics(equal: Box(0), Box(0))
    Box(1).checkHashableSemantics(equal: Box(1), Box(1))
  }

  /// Shows that testing Hashable also tests Equatable
  func testEquatableFailures() {
    let r = EquatableTests.irreflexiveSamples
    checkXCAssertionFailure(r[0].checkHashableSemantics(equal: r[1], r[2]), "reflexivity")
    
    let s = EquatableTests.asymmetricSamples
    checkXCAssertionFailure(s[0].checkHashableSemantics(equal: s[1], s[2]), "symmetry")
    
    let t = EquatableTests.intransitiveSamples
    checkXCAssertionFailure(t[0].checkHashableSemantics(equal: t[1], t[2]), "transitivity")
  }

  func testHashableFailure() {
    let s = [0, 0, 0].map { BrokenFloat($0, butNot: .hashable(.hashValueIsConsistentWithEquality)) }
    
    s[0].checkEquatableSemantics(equal: s[1], s[2])
    
    checkXCAssertionFailure(
      s[0].checkHashableSemantics(equal: s[1], s[2]), "distinct hash")
  }
}

//
// - MARK: Comparable
//

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
    0.checkComparableSemantics(greater: 1, greaterStill: 2)
    (-2).checkComparableSemantics(greater: -1, greaterStill: 0)
  }
  
  func testDistinctInstances() {
    let box0 = Box(0), box0a = Box(0), box0b = Box(0)
    let box1 = Box(1), box1a = Box(1), box1b = Box(1)
    let box2 = Box(2)
    let box3 = Box(3)
    box0.checkComparableSemantics(equal: box0a, box0b, greater: box1, greaterStill: box2)
    box1.checkComparableSemantics(equal: box1a, box1b, greater: box2, greaterStill: box3)
  }

  /// Shows that testing Comparable also tests Equatable
  func testEquatableFailures() {
    let r = EquatableTests.irreflexiveSamples

    checkXCAssertionFailure(
      r[0].checkComparableSemantics(equal: r[1], r[2], greater: r[3], greaterStill: r[4]),
      "reflexivity")

    let s = EquatableTests.asymmetricSamples
    checkXCAssertionFailure(
      s[0].checkComparableSemantics(equal: s[1], s[2], greater: s[3], greaterStill: s[4]),
      "symmetry")
    
    let t = EquatableTests.intransitiveSamples
    checkXCAssertionFailure(
      t[0].checkComparableSemantics(equal: t[1], t[2], greater: t[3], greaterStill: t[4]),
      "transitivity")
  }

  func testComparableFailures() {
    let s = [0, 0, 0].map { BrokenFloat($0, butNot: .hashable(.hashValueIsConsistentWithEquality)) }
    
    s[0].checkEquatableSemantics(equal: s[1], s[2])
  }
}

// Local Variables:
// fill-column: 100
// End: