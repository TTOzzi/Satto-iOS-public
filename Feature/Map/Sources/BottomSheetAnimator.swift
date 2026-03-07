//
//  BottomSheetAnimator.swift
//  Map
//
//  Created by Codex on 3/7/26.
//

import UIKit

@MainActor
final class BottomSheetAnimator {

  private enum VisibilityState {
    case shown
    case hidden
  }

  private let duration: TimeInterval
  private let hiddenOffset: CGFloat
  private var targetState: VisibilityState = .hidden

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
    targetState = .shown
    sheetView.layer.removeAllAnimations()
    sheetView.isHidden = false

    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: [.beginFromCurrentState, .curveEaseInOut]
    ) {
      sheetView.alpha = 1
      sheetView.transform = .identity
      animations?()
      containerView.layoutIfNeeded()
    } completion: { _ in
      guard self.targetState == .shown else { return }
      completion?()
    }
  }

  func hide(
    sheetView: UIView,
    in containerView: UIView,
    alongside animations: (() -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    targetState = .hidden
    sheetView.layer.removeAllAnimations()

    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: [.beginFromCurrentState, .curveEaseInOut]
    ) {
      sheetView.alpha = 0
      sheetView.transform = CGAffineTransform(translationX: 0, y: self.hiddenOffset)
      animations?()
      containerView.layoutIfNeeded()
    } completion: { _ in
      guard self.targetState == .hidden else { return }
      sheetView.isHidden = true
      completion?()
    }
  }
}
