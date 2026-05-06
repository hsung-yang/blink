////////////////////////////////////////////////////////////////////////////////
//
// RemoteTerm — SplitPaneController
// iTerm2-style recursive split pane container for Blink Shell
//
////////////////////////////////////////////////////////////////////////////////

import UIKit

extension Notification.Name {
  static let splitPaneDidChangeFocus = Notification.Name("splitPaneDidChangeFocus")
}

@objc enum SplitDirection: Int {
  case horizontal // side by side (left | right)
  case vertical   // stacked (top / bottom)
}

// MARK: - SplitPaneController

/// Wraps a TermController and supports recursive horizontal/vertical splits.
/// Replaces TermController as the direct child of SpaceController's UIPageViewController.
class SplitPaneController: UIViewController {

  // The currently focused leaf TermController
  private(set) var activeTerm: TermController?

  // Root of the split tree
  private var _root: SplitNode<TermController>

  init(term: TermController) {
    _root = SplitNode.leaf(term)
    activeTerm = term
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    _installNode(_root, path: [], in: view)
    _activateTerm(activeTerm)
  }

  // MARK: Split actions

  func splitActive(_ direction: SplitDirection) {
    guard let active = activeTerm else { return }
    let newTerm = _makeNewTerm()
    _split(leaf: active, with: newTerm, direction: direction)
    _activateTerm(newTerm)
  }

  func closeActive() {
    guard let active = activeTerm else { return }
    _close(leaf: active)
  }

  func focusNext() {
    let leaves = _root.allLeaves()
    guard let idx = leaves.firstIndex(where: { $0 === activeTerm }),
          leaves.count > 1
    else { return }
    _activateTerm(leaves[(idx + 1) % leaves.count])
  }

  func focusPrev() {
    let leaves = _root.allLeaves()
    guard let idx = leaves.firstIndex(where: { $0 === activeTerm }),
          leaves.count > 1
    else { return }
    _activateTerm(leaves[(idx - 1 + leaves.count) % leaves.count])
  }

  // MARK: Private

  private func _makeNewTerm() -> TermController {
    let term = TermController(sceneRole: .windowApplication, sessionPayload: MCPSessionPayload(params: MCPParams()))
    SessionRegistry.shared.track(session: term)
    return term
  }

  private func _split(leaf: TermController, with newTerm: TermController, direction: SplitDirection) {
    _root = _root.split(leaf: leaf, with: newTerm, direction: direction)
    _relayout()
  }

  private func _close(leaf: TermController) {
    guard _root.allLeaves().count > 1 else { return }
    _root = _root.close(leaf: leaf) ?? _root
    if activeTerm === leaf {
      activeTerm = _root.allLeaves().first
    }
    _relayout()
    leaf.terminate()
    SessionRegistry.shared.remove(forKey: leaf.meta.key)
  }

  private func _activateTerm(_ term: TermController?) {
    activeTerm = term
    for leaf in _root.allLeaves() {
      leaf.view?.layer.borderWidth = (leaf === term) ? 2 : 0
      leaf.view?.layer.borderColor = (leaf === term) ? UIColor.systemBlue.cgColor : nil
    }
    term?.activateInput()
    NotificationCenter.default.post(name: .splitPaneDidChangeFocus, object: self)
  }

  private func _relayout() {
    // Remove all children
    children.forEach { child in
      child.willMove(toParent: nil)
      child.view.removeFromSuperview()
      child.removeFromParent()
    }
    view.subviews.forEach { $0.removeFromSuperview() }
    // Reinstall tree
    _installNode(_root, path: [], in: view)
    _activateTerm(activeTerm)
  }

  private func _installNode(_ node: SplitNode<TermController>, path: [Int], in container: UIView) {
    switch node {
    case .leaf(let term):
      addChild(term)
      term.view.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(term.view)
      NSLayoutConstraint.activate([
        term.view.topAnchor.constraint(equalTo: container.topAnchor),
        term.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        term.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        term.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
      ])
      term.didMove(toParent: self)

    case .split(let first, let second, let direction, let ratio):
      let divider = SplitDividerView(direction: direction)
      divider.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(divider)

      let firstContainer = UIView()
      firstContainer.translatesAutoresizingMaskIntoConstraints = false
      let secondContainer = UIView()
      secondContainer.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(firstContainer)
      container.addSubview(secondContainer)

      let dividerThickness: CGFloat = 4

      if direction == .horizontal {
        // Side by side
        let firstWidthConstraint = firstContainer.widthAnchor.constraint(
          equalTo: container.widthAnchor,
          multiplier: ratio,
          constant: -dividerThickness / 2
        )
        firstWidthConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
          firstContainer.topAnchor.constraint(equalTo: container.topAnchor),
          firstContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
          firstContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          firstWidthConstraint,

          divider.topAnchor.constraint(equalTo: container.topAnchor),
          divider.leadingAnchor.constraint(equalTo: firstContainer.trailingAnchor),
          divider.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          divider.widthAnchor.constraint(equalToConstant: dividerThickness),

          secondContainer.topAnchor.constraint(equalTo: container.topAnchor),
          secondContainer.leadingAnchor.constraint(equalTo: divider.trailingAnchor),
          secondContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
          secondContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        divider.onDrag = { [weak self, weak container] delta in
          guard let self, let container else { return }
          let total = container.bounds.width
          let newRatio = SplitNode<TermController>.clampedRatio(ratio + delta / total)
          self._root = self._root.updateRatio(at: path, to: newRatio)
          self._relayout()
        }
      } else {
        // Stacked
        let firstHeightConstraint = firstContainer.heightAnchor.constraint(
          equalTo: container.heightAnchor,
          multiplier: ratio,
          constant: -dividerThickness / 2
        )
        firstHeightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
          firstContainer.topAnchor.constraint(equalTo: container.topAnchor),
          firstContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
          firstContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
          firstHeightConstraint,

          divider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
          divider.topAnchor.constraint(equalTo: firstContainer.bottomAnchor),
          divider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
          divider.heightAnchor.constraint(equalToConstant: dividerThickness),

          secondContainer.topAnchor.constraint(equalTo: divider.bottomAnchor),
          secondContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
          secondContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
          secondContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        divider.onDrag = { [weak self, weak container] delta in
          guard let self, let container else { return }
          let total = container.bounds.height
          let newRatio = SplitNode<TermController>.clampedRatio(ratio + delta / total)
          self._root = self._root.updateRatio(at: path, to: newRatio)
          self._relayout()
        }
      }

      _installNode(first, path: path + [0], in: firstContainer)
      _installNode(second, path: path + [1], in: secondContainer)
    }
  }
}

// MARK: - SplitNode (recursive tree)

indirect enum SplitNode<Leaf: AnyObject> {
  case leaf(Leaf)
  case split(SplitNode<Leaf>, SplitNode<Leaf>, SplitDirection, CGFloat) // ratio 0..1

  static func clampedRatio(_ r: CGFloat) -> CGFloat {
    max(0.15, min(0.85, r))
  }

  func allLeaves() -> [Leaf] {
    switch self {
    case .leaf(let t): return [t]
    case .split(let a, let b, _, _): return a.allLeaves() + b.allLeaves()
    }
  }

  func split(leaf target: Leaf, with newTerm: Leaf, direction: SplitDirection) -> SplitNode<Leaf> {
    switch self {
    case .leaf(let t) where t === target:
      return .split(.leaf(t), .leaf(newTerm), direction, 0.5)
    case .leaf:
      return self
    case .split(let a, let b, let dir, let ratio):
      return .split(
        a.split(leaf: target, with: newTerm, direction: direction),
        b.split(leaf: target, with: newTerm, direction: direction),
        dir, ratio
      )
    }
  }

  func close(leaf target: Leaf) -> SplitNode<Leaf>? {
    switch self {
    case .leaf(let t): return t === target ? nil : self
    case .split(let a, let b, let dir, let ratio):
      let newA = a.close(leaf: target)
      let newB = b.close(leaf: target)
      switch (newA, newB) {
      case (nil, let n?): return n
      case (let n?, nil): return n
      case (let na?, let nb?): return .split(na, nb, dir, ratio)
      case (nil, nil): return nil
      }
    }
  }

  /// Update the ratio at a specific path through the tree.
  /// Path is a sequence of 0/1 child indices (0 = first/left/top, 1 = second/right/bottom).
  /// Empty path targets self. No-op if path traverses a leaf or self is a leaf.
  func updateRatio(at path: [Int], to newRatio: CGFloat) -> SplitNode<Leaf> {
    guard case .split(let a, let b, let dir, let ratio) = self else { return self }
    if path.isEmpty {
      return .split(a, b, dir, newRatio)
    }
    let next = Array(path.dropFirst())
    if path[0] == 0 {
      return .split(a.updateRatio(at: next, to: newRatio), b, dir, ratio)
    }
    return .split(a, b.updateRatio(at: next, to: newRatio), dir, ratio)
  }
}
