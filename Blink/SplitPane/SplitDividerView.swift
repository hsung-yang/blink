////////////////////////////////////////////////////////////////////////////////
//
// RemoteTerm — SplitDividerView
// Draggable divider between split panes, with Mac pointer cursor support
//
////////////////////////////////////////////////////////////////////////////////

import UIKit

class SplitDividerView: UIView {

  var onDrag: ((CGFloat) -> Void)?

  private let _direction: SplitDirection
  private var _panStart: CGFloat = 0

  init(direction: SplitDirection) {
    _direction = direction
    super.init(frame: .zero)
    backgroundColor = UIColor(white: 0.2, alpha: 1)
    _setupGestures()
    _setupPointer()
  }

  required init?(coder: NSCoder) { fatalError() }

  // MARK: Gestures

  private func _setupGestures() {
    let pan = UIPanGestureRecognizer(target: self, action: #selector(_handlePan(_:)))
    pan.maximumNumberOfTouches = 1
    addGestureRecognizer(pan)
  }

  @objc private func _handlePan(_ pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: superview)
    let delta = _direction == .horizontal ? translation.x : translation.y
    switch pan.state {
    case .began:
      _panStart = 0
    case .changed:
      let increment = delta - _panStart
      _panStart = delta
      onDrag?(increment)
    default: break
    }
  }

  // MARK: Pointer (Mac trackpad + iPad Pointer)

  private func _setupPointer() {
    let hover = UIHoverGestureRecognizer(target: self, action: #selector(_handleHover(_:)))
    addGestureRecognizer(hover)

    let interaction = UIPointerInteraction(delegate: self)
    addInteraction(interaction)
  }

  @objc private func _handleHover(_ recognizer: UIHoverGestureRecognizer) {
    // Cursor change handled by UIPointerInteraction delegate below
  }
}

// MARK: - UIPointerInteractionDelegate

extension SplitDividerView: UIPointerInteractionDelegate {
  func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
    let preview = UITargetedPreview(view: self)
    let effect = UIPointerEffect.highlight(preview)
    let path = UIBezierPath(rect: bounds)
    let shape = UIPointerShape.path(path)
    return UIPointerStyle(effect: effect, shape: shape)
  }
}
