////////////////////////////////////////////////////////////////////////////////
//
// RemoteTerm — QuickActionsHandle
// Visible pill trigger for the Quick Actions overlay.
//
////////////////////////////////////////////////////////////////////////////////

import UIKit

final class QuickActionsHandle: UIView {

  private let _blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
  private let _chevron = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    accessibilityIdentifier = "quick-actions-handle"
    isAccessibilityElement = true
    accessibilityLabel = "Quick Actions"
    _blur.layer.cornerRadius = 10
    _blur.layer.cornerCurve = .continuous
    _blur.clipsToBounds = true
    _blur.alpha = 0.85
    addSubview(_blur)

    let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
    _chevron.image = UIImage(systemName: "chevron.up", withConfiguration: cfg)
    _chevron.tintColor = UIColor(white: 1, alpha: 0.75)
    _chevron.contentMode = .scaleAspectFit
    _blur.contentView.addSubview(_chevron)
  }

  required init?(coder: NSCoder) { fatalError() }

  override func layoutSubviews() {
    super.layoutSubviews()
    _blur.frame = bounds
    _chevron.frame = bounds.insetBy(dx: 14, dy: 8)
  }

  // Extend touch target beyond visual frame so the tiny pill is easy to hit.
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    bounds.insetBy(dx: -20, dy: -24).contains(point)
  }
}
