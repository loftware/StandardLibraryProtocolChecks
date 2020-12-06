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
// MARK: - Equatable
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

//
// MARK: - Hashable
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
    0.checkHashableLaws()
    1.checkHashableLaws()
  }
  
  func testDistinctInstances() {
    Box(0).checkHashableLaws(equal: Box(0), Box(0))
    Box(1).checkHashableLaws(equal: Box(1), Box(1))
  }

  /// Shows that testing Hashable also tests Equatable
  func testEquatableFailures() {
    let r = EquatableTests.irreflexiveSamples
    checkXCAssertionFailure(
      r[0].checkHashableLaws(equal: r[1], r[2]), messageExcerpt:  "reflexivity")
    
    let s = EquatableTests.asymmetricSamples
    checkXCAssertionFailure(
      s[0].checkHashableLaws(equal: s[1], s[2]), messageExcerpt:  "symmetry")
    
    let t = EquatableTests.intransitiveSamples
    checkXCAssertionFailure(
      t[0].checkHashableLaws(equal: t[1], t[2]), messageExcerpt:  "transitivity")
  }

  func testHashableFailure() {
    let s = [0, 0, 0].map { BrokenFloat($0, butNot: .hashable(.hashValueIsConsistentWithEquality)) }
    
    s[0].checkEquatableLaws(equal: s[1], s[2])
    
    checkXCAssertionFailure(
      s[0].checkHashableLaws(equal: s[1], s[2]), messageExcerpt:  "distinct hash")
  }
}

//
// MARK: - Comparable
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

//
// MARK: - Sequence
//

/// A sequence of Ints with as few assumptions as possible
final class TestSequence: Sequence, IteratorProtocol {
  var x = 0
  let end: Int
  let resurrectMe: Bool
  
  init(end: Int, illegalRessurection: Bool = false) {
    self.end = end
    resurrectMe = illegalRessurection
  }
  
  func next() -> Int? {
    if x == end {
      if resurrectMe { x += 1 }
      return nil
    }
    defer { x += 1 }
    return x
  }
}

class SequenceTests: CheckXCAssertionFailureTestCase {
  func testSuccess() {
    TestSequence(end: 20).checkSequenceLaws(expecting: 0..<20)
    (0..<20).checkSequenceLaws(expecting: 0..<20)
  }

  func testElementMismatch() {
    checkXCAssertionFailure(
      TestSequence(end: 20).checkSequenceLaws(expecting: 1..<21))
  }

  func testMissingElements() {
    checkXCAssertionFailure(
      TestSequence(end: 20).checkSequenceLaws(expecting: 0..<25))
  }

  func testIteratorRessurrection() {
    checkXCAssertionFailure(
      TestSequence(end: 20, illegalRessurection: true).checkSequenceLaws(expecting: 0..<20))
  }
}

//
// MARK: - Collection
//

/// A collection ostensibly equivalent to 0..<20 but with some laws optionally broken.
final class TestCollection: Collection {
  enum Law {
    case
      // Sequence laws
      iteratorDoesNotResurrect,
         
      // Collection laws     
      sequenceElementsMatch,         
      indicesPropertyElementsMatch,
      indicesPropertySameLengthAsSelf,
      indicesAreStrictlyIncreasing,
      forwardIndexOffsetByWorks,
      indexOffsetByLimitedByEndIndexMatchesIndexOffsetBy,
      forwardIndexOffsetByLimitedByRespectsLimit,
      forwardDistanceWorks,
      isMultipass,
      
      // BidirectionalCollection laws
      indexBeforeUndoesIndexAfter,
      reverseIndexOffsetByWorks,
      indexOffsetByLimitedByStartIndexMatchesIndexOffsetBy,
      reverseIndexOffsetByLimitedByRespectsLimit,
      reverseDistanceWorks
  }

  init(brokenLaw: Law?) { self.brokenLaw = brokenLaw }
  
  let brokenLaw: Law?
  var pass = 0
  
  struct Iterator: IteratorProtocol {
    let brokenLaw: Law?
    var parent: TestCollection
    var value = 0
    
    mutating func next() -> Int? {
      defer { 
        if value != 20 || brokenLaw == .iteratorDoesNotResurrect {
          value += 1
        }
      }
      if value == 20 {
        return nil
      }
      if value == 19 {
        defer { parent.pass += 1 }
        if brokenLaw == .sequenceElementsMatch { return 20 }
        if brokenLaw == .isMultipass { return 19 + parent.pass }
      }
      return value
    }
  }
  
  func makeIterator() -> Iterator { .init(brokenLaw: brokenLaw, parent: self) }

  struct Index : Comparable {
    let brokenLaw: Law?
    var x: Int
    
    init(_ x: Int, brokenLaw: Law?) {
      self.x = x
      self.brokenLaw = brokenLaw
    }
    
    static func == (_ l: Self, _ r: Self) -> Bool { l.x == r.x }
    
    static func < (_ l: Self, _ r: Self) -> Bool {
      let l0 = l.brokenLaw == .indicesAreStrictlyIncreasing && l.x == 10
        ? 11 : l.x
      let r0 = r.brokenLaw == .indicesAreStrictlyIncreasing && r.x == 10
        ? 11 : r.x
      return l0 < r0
    }
  }

  struct IndicesBase: Collection {
    let brokenLaw: Law?

    typealias Indices = Slice<IndicesBase>
    var indices: Indices { self[...] }
    typealias Index = TestCollection.Index
    subscript(i: Index) -> Index { i }
    func index(after i: Index) -> Index {
      .init(i.x + (brokenLaw == .indicesPropertyElementsMatch ? 2 : 1), brokenLaw: i.brokenLaw)
    }
    var startIndex: Index { .init(0, brokenLaw: brokenLaw) }
    var endIndex: Index {
      .init(
        brokenLaw == .indicesPropertySameLengthAsSelf
          ? 21 : 20, brokenLaw: brokenLaw)
    }

    // Needed to work around https://bugs.swift.org/browse/SR-13937
    func distance(from x: Index, to y: Index) -> Int {
      return TestCollection(brokenLaw: brokenLaw).distance(from: x, to: y)
    }
  }
  
  typealias Indices = IndicesBase.SubSequence
  
  var indices: Indices {
    IndicesBase(brokenLaw: brokenLaw)[...]
  }
  
  var startIndex: Index { .init(0, brokenLaw: brokenLaw) }
  var endIndex: Index { .init(20, brokenLaw: brokenLaw) }

  subscript(i: Index) -> Int {
    if i.x == 19 {
      defer { pass += 1 }
      if brokenLaw == .isMultipass && pass > 0 { return 19 + pass }
    }
    return i.x
  }
  
  func index(after i: Index) -> Index {
    .init(i.x + 1, brokenLaw: i.brokenLaw)
  }

  func index(_ i: Index, offsetBy n: Int) -> Index {
    let offset
      = n > 0 && brokenLaw == .forwardIndexOffsetByWorks
      || n < 0 && brokenLaw == .reverseIndexOffsetByWorks ? n * 100 / 88 : n
    return .init(i.x + offset, brokenLaw: brokenLaw)
  }

  func index(_ i: Index, offsetBy offset: Int, limitedBy limit: Index) -> Index? {
    var n = offset
    if limit == endIndex
         && brokenLaw == .indexOffsetByLimitedByEndIndexMatchesIndexOffsetBy
    {
      if n > 2 { n -= 1 }
    }
    else if limit == startIndex
              && brokenLaw == .indexOffsetByLimitedByStartIndexMatchesIndexOffsetBy
    {
      if n < -2 { n += 1 }
    }
    
    if brokenLaw != .forwardIndexOffsetByLimitedByRespectsLimit 
      && i.x <= limit.x && i.x + n > limit.x
      || brokenLaw != .reverseIndexOffsetByLimitedByRespectsLimit
      && i.x >= limit.x && i.x + n < limit.x
    {
      return nil
    }
    return index(i, offsetBy: n)
  }

  func distance(from i: Index, to j: Index) -> Int {
    let d = j.x - i.x
    return d > 0 && brokenLaw == .forwardDistanceWorks
      || d < 0 && brokenLaw == .reverseDistanceWorks ? d * 100 / 95 : d
  }
}

class CollectionTests: CheckXCAssertionFailureTestCase {
  func testSuccess() {
    TestCollection(brokenLaw: nil).checkCollectionLaws(expecting: 0..<20)
    (0..<20).checkCollectionLaws(expecting: 0..<20)
  }

  func testFailSequenceElementsMatch() {
    checkXCAssertionFailure(
      TestCollection(brokenLaw: .sequenceElementsMatch)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "iterator/subscript access mismatch")
  }

  func testFailIteratorDoesNotResurrect() {
    checkXCAssertionFailure(
      TestCollection(brokenLaw: .iteratorDoesNotResurrect)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "Exhausted iterator expected to return nil from next")
  }

  func testFailIndicesPropertyElementsMatch() {
    checkXCAssertionFailure(
      TestCollection(brokenLaw: .indicesPropertyElementsMatch)
        .checkCollectionLaws(expecting: 0..<20),
        messageExcerpt: "elements of indices property don't match index(after:)")
  }

  func testFailIndicesPropertySameLengthAsSelf() {
    checkXCAssertionFailure(
      TestCollection(brokenLaw: .indicesPropertySameLengthAsSelf)
        .checkCollectionLaws(expecting: 0..<20),
        messageExcerpt: "indices property has too many elements")
  }

  func testFailIndicesAreStrictlyIncreasing() {
    checkXCAssertionFailure(
      TestCollection(brokenLaw: .indicesAreStrictlyIncreasing)
        .checkCollectionLaws(expecting: 0..<20),
        messageExcerpt: "indices are not strictly increasing")
  }
  
  func testFailForwardIndexOffsetByWorks() {
    checkXCAssertionFailure(
      TestCollection(brokenLaw: .forwardIndexOffsetByWorks)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:) offset >= 0, unexpected result")
  }
  
  func testFailForwardIndexOffsetByLimitedByEndIndexMatchesIndexOffsetBy() {
    checkXCAssertionFailure(
      TestCollection(
        brokenLaw: .indexOffsetByLimitedByEndIndexMatchesIndexOffsetBy)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:limitedBy: endIndex) offset >= 0, limit not exceeded")
  }
  
  func testFailForwardIndexOffsetByLimitedByRespectsLimit() {
    checkXCAssertionFailure(
      TestCollection(
        brokenLaw: .forwardIndexOffsetByLimitedByRespectsLimit)
        .checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:limitedBy:) offset > 0, limit not respected")
  }
  
  func testFailForwardDistanceWorks() {
    checkXCAssertionFailure(
      TestCollection(
        brokenLaw: .forwardDistanceWorks).checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "distance(from: i, to: j), i < j unexpected result")
  }
  
  func testFailIsMultipass() {
    checkXCAssertionFailure(
      TestCollection(
        brokenLaw: .isMultipass).checkCollectionLaws(expecting: 0..<20),
      messageExcerpt: "multipass")
  }
}

//
// MARK: - BidirectionalCollection
//
extension TestCollection: BidirectionalCollection {
  func index(before i: Index) -> Index {
    .init(
      i.x - (brokenLaw == .indexBeforeUndoesIndexAfter && i.x > 5 ? 2 : 1),
      brokenLaw: i.brokenLaw)
  }
}

extension TestCollection.IndicesBase : BidirectionalCollection {
  func index(before i: Index) -> Index {
    .init(
      i.x - (brokenLaw == .indexBeforeUndoesIndexAfter && i.x > 5 ? 2 : 1),
      brokenLaw: i.brokenLaw)
  }
}

class BidirectionalCollectionTests: CheckXCAssertionFailureTestCase {
  func testSuccess() {
    TestCollection(brokenLaw: nil).checkBidirectionalCollectionLaws(expecting: 0..<20)
    (0..<20).checkBidirectionalCollectionLaws(expecting: 0..<20)
  }

  func testFailIndexBeforeUndoesIndexAfter() {
    checkXCAssertionFailure(
      TestCollection(brokenLaw: .indexBeforeUndoesIndexAfter)
        .checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(after:) does not undo index(before:)")
  }

  func testFailReverseIndexOffsetByWorks() {
    checkXCAssertionFailure(
      TestCollection(brokenLaw: .reverseIndexOffsetByWorks)
        .checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:) offset <= 0, unexpected result")
  }
  
  func testFailReverseIndexOffsetByLimitedByEndIndexMatchesIndexOffsetBy() {
    checkXCAssertionFailure(
      TestCollection(
        brokenLaw: .indexOffsetByLimitedByStartIndexMatchesIndexOffsetBy)
        .checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:limitedBy: startIndex) offset <= 0, limit not exceeded")
  }
  
  func testFailReverseIndexOffsetByLimitedByRespectsLimit() {
    checkXCAssertionFailure(
      TestCollection(
        brokenLaw: .reverseIndexOffsetByLimitedByRespectsLimit)
        .checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "index(offsetBy:limitedBy:) offset < 0, limit not respected")
  }
  
  func testFailReverseDistanceWorks() {
    checkXCAssertionFailure(
      TestCollection(
        brokenLaw: .reverseDistanceWorks).checkBidirectionalCollectionLaws(expecting: 0..<20),
      messageExcerpt: "distance(from: i, to: j), j < i unexpected result")
  }
}

//
// MARK: - RandomAccessCollection
//
struct TestAdaptor<Base: RandomAccessCollection> {
  enum Law {
    case
      // RandomAccessCollection laws
      forwardDistanceIsO1,
      reverseDistanceIsO1,
      forwardIndexOffsetByIsO1,
      reverseIndexOffsetByIsO1,
      forwardIndexOffsetByLimitedByIsO1,
      reverseIndexOffsetByLimitedByIsO1
  }

  var base: Base
  let brokenLaw: Law?
}

extension TestAdaptor: Collection {
  typealias Index = Base.Index
  var startIndex: Base.Index { base.startIndex }
  var endIndex: Base.Index { base.endIndex }

  subscript(i: Index) -> Base.Element { base[i] }

  func index(after i: Index) -> Index { return base.index(after: i) }
  func index(before i: Index) -> Index { return base.index(before: i) }

  func index(_ i: Index, offsetBy n: Int) -> Index {
    var i1 = i
    if n > 0 && brokenLaw == .forwardIndexOffsetByIsO1 {
      for _ in 0..<n { formIndex(after: &i1) }
      return i1
    }
    if n < 0 && brokenLaw == .reverseIndexOffsetByIsO1 {
      for _ in n..<0 { formIndex(before: &i1) }
      return i1
    }
    return base.index(i, offsetBy: n)
  }

  func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    var i1 = i
    if n > 0 && brokenLaw == .forwardIndexOffsetByLimitedByIsO1 {
      for _ in 0..<n {
        if i1 == limit { return nil }
        formIndex(after: &i1)
      }
      return i1
    }
    if n < 0 && brokenLaw == .reverseIndexOffsetByLimitedByIsO1 {
      for _ in n..<0 {
        if i1 == limit { return nil }
        formIndex(before: &i1)
      }
      return i1
    }
    return base.index(i, offsetBy: n, limitedBy: limit)
  }

  func distance(from i: Index, to j: Index) -> Int {
    if i < j {
      if brokenLaw == .forwardDistanceIsO1 {
        var i1 = i, n = 0
        while i1 != j { formIndex(after: &i1); n += 1 }
        return n
      }
    }
    else {
      if brokenLaw == .reverseDistanceIsO1 {
        var j1 = j, n = 0
        while j1 != i { formIndex(after: &j1); n -= 1 }
        return n
      }
    }
    return base.distance(from: i, to: j)
  }
}

extension TestAdaptor: RandomAccessCollection, RandomAccessCollectionAdapter {}

class RandomAccessCollectionTests: CheckXCAssertionFailureTestCase {
  func makeBase() -> RandomAccessOperationCounter<Range<Int>> {
    RandomAccessOperationCounter(0..<20)
  }
  
  func testSuccess() {
    let base = makeBase()
    TestAdaptor(base: base, brokenLaw: nil)
      .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts)
  }

  func testFailForwardDistanceIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      TestAdaptor(base: base, brokenLaw: .forwardDistanceIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "distance(from: i, to: j) i <= j is not O(1)")
  }

  func testFailReverseDistanceIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      TestAdaptor(base: base, brokenLaw:  .reverseDistanceIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "distance(from: i, to: j) j <= i is not O(1)")
  }

  func testFailForwardIndexOffsetByIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      TestAdaptor(base: base, brokenLaw: .forwardIndexOffsetByIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "index(:offsetBy: i) i >= 0 is not O(1)")
  }

  func testFailReverseIndexOffsetByIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      TestAdaptor(base: base, brokenLaw:  .reverseIndexOffsetByIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "index(:offsetBy: i) i <= 0 is not O(1)")
  }
  
  func testFailForwardIndexOffsetByLimitedByIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      TestAdaptor(base: base, brokenLaw: .forwardIndexOffsetByLimitedByIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "index(:offsetBy: i, limitedBy:) i >= 0 is not O(1)")
  }

  func testFailReverseIndexOffsetByLimitedByIs01() {
    let base = makeBase()
    checkXCAssertionFailure(
      TestAdaptor(base: base, brokenLaw:  .reverseIndexOffsetByLimitedByIsO1)
        .checkRandomAccessCollectionLaws(expecting: 0..<20, operationCounts: base.operationCounts),
      messageExcerpt: "index(:offsetBy: i, limitedBy:) i <= 0 is not O(1)")
  }
}

/// A Really simple adapter over any `Base` that presents the same elements.
struct TrivialAdapter<Base: RandomAccessCollection>: RandomAccessCollection {
  var base: Base
  typealias Index = Base.Index
  var startIndex: Base.Index { base.startIndex }
  var endIndex: Base.Index { base.endIndex }

  subscript(i: Index) -> Base.Element { base[i] }

  func index(after i: Index) -> Index { return base.index(after: i) }
  func index(before i: Index) -> Index { return base.index(before: i) }
}

extension TrivialAdapter: RandomAccessCollectionAdapter {}

class TestExample: CheckXCAssertionFailureTestCase {
  func testLaws() {
    // Create a collection with operation counting.
    let counter = RandomAccessOperationCounter(0..<20)
    
    // Now adapt it with our adapter
    let testSubject = TrivialAdapter(base: counter)
    
    checkXCAssertionFailure(
      testSubject.checkRandomAccessCollectionLaws(
        expecting: 0..<20, operationCounts: counter.operationCounts),
      messageExcerpt: "O(1)")
  }
}

// Local Variables:
// fill-column: 100
// End:
