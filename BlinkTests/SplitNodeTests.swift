import XCTest
@testable import Blink

private final class MockTerm {
  let id: Int
  init(_ id: Int) { self.id = id }
}

final class SplitNodeTests: XCTestCase {

  func testLeafReturnsSingleTerm() {
    let t = MockTerm(1)
    let n: SplitNode<MockTerm> = .leaf(t)
    XCTAssertEqual(n.allLeaves().map { $0.id }, [1])
  }

  func testSplitOnLeafProducesTwoLeaves() {
    let a = MockTerm(1)
    let b = MockTerm(2)
    var n: SplitNode<MockTerm> = .leaf(a)
    n = n.split(leaf: a, with: b, direction: .horizontal)
    XCTAssertEqual(n.allLeaves().map { $0.id }, [1, 2])
  }

  func testSplitOnNonMatchingLeafIsNoOp() {
    let a = MockTerm(1)
    let b = MockTerm(2)
    let c = MockTerm(3)
    var n: SplitNode<MockTerm> = .leaf(a)
    n = n.split(leaf: b, with: c, direction: .vertical)
    XCTAssertEqual(n.allLeaves().map { $0.id }, [1])
  }

  func testNestedSplits() {
    let a = MockTerm(1), b = MockTerm(2), c = MockTerm(3)
    var n: SplitNode<MockTerm> = .leaf(a)
    n = n.split(leaf: a, with: b, direction: .horizontal)
    n = n.split(leaf: b, with: c, direction: .vertical)
    XCTAssertEqual(n.allLeaves().map { $0.id }, [1, 2, 3])
  }

  func testCloseLastLeafReturnsNil() {
    let a = MockTerm(1)
    let n: SplitNode<MockTerm> = .leaf(a)
    XCTAssertNil(n.close(leaf: a))
  }

  func testCloseOneOfTwoCollapses() {
    let a = MockTerm(1), b = MockTerm(2)
    var n: SplitNode<MockTerm> = .leaf(a)
    n = n.split(leaf: a, with: b, direction: .horizontal)
    let after = n.close(leaf: a)
    XCTAssertNotNil(after)
    XCTAssertEqual(after?.allLeaves().map { $0.id }, [2])
  }

  func testCloseInDeepTreePreservesSiblings() {
    let a = MockTerm(1), b = MockTerm(2), c = MockTerm(3)
    var n: SplitNode<MockTerm> = .leaf(a)
    n = n.split(leaf: a, with: b, direction: .horizontal)
    n = n.split(leaf: b, with: c, direction: .vertical)
    let after = n.close(leaf: c)
    XCTAssertEqual(after?.allLeaves().map { $0.id }, [1, 2])
  }

  func testCloseNonExistentLeafIsNoOp() {
    let a = MockTerm(1), b = MockTerm(2), other = MockTerm(99)
    var n: SplitNode<MockTerm> = .leaf(a)
    n = n.split(leaf: a, with: b, direction: .horizontal)
    let after = n.close(leaf: other)
    XCTAssertEqual(after?.allLeaves().map { $0.id }, [1, 2])
  }

  func testSplitDefaultRatioIsHalf() {
    let a = MockTerm(1), b = MockTerm(2)
    var n: SplitNode<MockTerm> = .leaf(a)
    n = n.split(leaf: a, with: b, direction: .horizontal)
    if case .split(_, _, _, let ratio) = n {
      XCTAssertEqual(ratio, 0.5, accuracy: 0.001)
    } else {
      XCTFail("expected split")
    }
  }

  func testSplitDirectionPreserved() {
    let a = MockTerm(1), b = MockTerm(2)
    var n: SplitNode<MockTerm> = .leaf(a)
    n = n.split(leaf: a, with: b, direction: .vertical)
    if case .split(_, _, let dir, _) = n {
      XCTAssertEqual(dir, .vertical)
    } else {
      XCTFail("expected split")
    }
  }

  // MARK: - FR-SPLIT-4 clampedRatio bounds tests

  func testClampBelowMinimum() {
    XCTAssertEqual(SplitNode<MockTerm>.clampedRatio(0.0), 0.15, accuracy: 0.001)
  }

  func testClampAboveMaximum() {
    XCTAssertEqual(SplitNode<MockTerm>.clampedRatio(1.0), 0.85, accuracy: 0.001)
  }

  func testClampInRangePassthrough() {
    XCTAssertEqual(SplitNode<MockTerm>.clampedRatio(0.5), 0.5, accuracy: 0.001)
  }

  func testClampNaN() {
    let result = SplitNode<MockTerm>.clampedRatio(.nan)
    // Swift's min(0.85, .nan) returns 0.85 (non-NaN wins), then max(0.15, 0.85) = 0.85
    XCTAssertEqual(result, 0.85, accuracy: 0.001)
  }

  // MARK: - updateRatio path-based addressing (KNOWN-001 fix)

  func testUpdateRatioOnlyModifiesTargetSubtree() {
    let a = MockTerm(1), b = MockTerm(2), c = MockTerm(3), d = MockTerm(4)

    // Build: split(split(a,b,h,0.4), split(c,d,h,0.4), v, 0.5)
    // Path [0] addresses the left subtree.
    let leftSplit: SplitNode<MockTerm> = .split(.leaf(a), .leaf(b), .horizontal, 0.4)
    let rightSplit: SplitNode<MockTerm> = .split(.leaf(c), .leaf(d), .horizontal, 0.4)
    let root: SplitNode<MockTerm> = .split(leftSplit, rightSplit, .vertical, 0.5)

    let updated = root.updateRatio(at: [0], to: 0.6)

    guard case .split(let newLeft, let newRight, _, let rootRatio) = updated else {
      XCTFail("expected split root"); return
    }
    XCTAssertEqual(rootRatio, 0.5, accuracy: 0.001, "root ratio unchanged")
    if case .split(_, _, _, let lr) = newLeft {
      XCTAssertEqual(lr, 0.6, accuracy: 0.001, "left subtree ratio updated")
    } else { XCTFail("expected split left") }
    if case .split(_, _, _, let rr) = newRight {
      XCTAssertEqual(rr, 0.4, accuracy: 0.001, "right subtree ratio unchanged")
    } else { XCTFail("expected split right") }
  }

  func testUpdateRatioAtRoot() {
    let a = MockTerm(1), b = MockTerm(2)
    let root: SplitNode<MockTerm> = .split(.leaf(a), .leaf(b), .horizontal, 0.5)
    let updated = root.updateRatio(at: [], to: 0.7)
    if case .split(_, _, _, let r) = updated {
      XCTAssertEqual(r, 0.7, accuracy: 0.001)
    } else { XCTFail("expected split") }
  }

  func testUpdateRatioDeepPath() {
    let a = MockTerm(1), b = MockTerm(2), c = MockTerm(3), d = MockTerm(4)
    // Build: split( split(a, split(b,c,h,0.4), v, 0.3), .leaf(d), h, 0.5)
    // Path [0, 1] targets the inner split(b,c,...).
    let bcSplit: SplitNode<MockTerm> = .split(.leaf(b), .leaf(c), .horizontal, 0.4)
    let leftSplit: SplitNode<MockTerm> = .split(.leaf(a), bcSplit, .vertical, 0.3)
    let root: SplitNode<MockTerm> = .split(leftSplit, .leaf(d), .horizontal, 0.5)

    let updated = root.updateRatio(at: [0, 1], to: 0.8)

    guard case .split(let newLeft, _, _, _) = updated else {
      XCTFail("expected split root"); return
    }
    guard case .split(_, let newBC, _, let leftRatio) = newLeft else {
      XCTFail("expected split left"); return
    }
    XCTAssertEqual(leftRatio, 0.3, accuracy: 0.001, "left subtree ratio unchanged")
    if case .split(_, _, _, let bcRatio) = newBC {
      XCTAssertEqual(bcRatio, 0.8, accuracy: 0.001, "deep target ratio updated")
    } else { XCTFail("expected split bc") }
  }

  func testUpdateRatioOnLeafIsNoOp() {
    let a = MockTerm(1)
    let root: SplitNode<MockTerm> = .leaf(a)
    let updated = root.updateRatio(at: [], to: 0.7)
    XCTAssertEqual(updated.allLeaves().map { $0.id }, [1])
  }
}
