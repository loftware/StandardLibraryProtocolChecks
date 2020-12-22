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

/// A collection ostensibly equivalent to 0..<20 but with some laws optionally broken.
final class FlawedCollection: Collection {
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
    var parent: FlawedCollection
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
    typealias Index = FlawedCollection.Index
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
      return FlawedCollection(brokenLaw: brokenLaw).distance(from: x, to: y)
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

extension FlawedCollection: BidirectionalCollection {
  func index(before i: Index) -> Index {
    .init(
      i.x - (brokenLaw == .indexBeforeUndoesIndexAfter && i.x > 5 ? 2 : 1),
      brokenLaw: i.brokenLaw)
  }
}

extension FlawedCollection.IndicesBase : BidirectionalCollection {
  func index(before i: Index) -> Index {
    .init(
      i.x - (brokenLaw == .indexBeforeUndoesIndexAfter && i.x > 5 ? 2 : 1),
      brokenLaw: i.brokenLaw)
  }
}

