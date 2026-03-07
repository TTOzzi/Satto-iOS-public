//
//  BottomSheetAnimator.swift
//  Map
//
//  Created by Codex on 3/7/26.
//

import UIKit

final class BottomSheetAnimator {

  private let duration: TimeInterval
  private let hiddenOffset: CGFloat

  init(duration: TimeInterval = 0.25, hiddenOffset: CGFloat = 200) {
    self.duration = duration
    self.hiddenOffset = hiddenOffset
  }

  func show(
    sheetView: UIView,
    in containerView: UIView,
    alongside animations: (() -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    sheetView.isHidden = false
    sheetView.transform = CGAffineTransform(translationX: 0, y: hiddenOffset)

    UIView.animate(withDuration: duration) {
      sheetView.alpha = 1
      sheetView.transform = .identity
      animations?()
      containerView.layoutIfNeeded()
    } completion: { _ in
      completion?()
    }
  }

  func hide(
    sheetView: UIView,
    in containerView: UIView,
    alongside animations: (() -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    UIView.animate(withDuration: duration) {
      sheetView.alpha = 0
      sheetView.transform = CGAffineTransform(translationX: 0, y: self.hiddenOffset)
      animations?()
      containerView.layoutIfNeeded()
    } completion: { _ in
      sheetView.isHidden = true
      completion?()
    }
  }
}
