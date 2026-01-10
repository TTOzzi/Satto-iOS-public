//
//  Tab.swift
//  Base
//
//  Created by ttozzi on 8/15/25.
//

import DesignSystem
import UIKit

enum Tab: CaseIterable {
  case home
  //  case fortune
  case pastLotto
  case map
  case my

  var title: String {
    switch self {
    case .home:
      return "홈"
    //    case .fortune:
    //      return "오늘 운세"
    case .pastLotto:
      return "뭐 나왔지"
    case .map:
      return "명소"
    case .my:
      return "마이"
    }
  }

  var icon: UIImage? {
    switch self {
    case .home:
      return STImages.home.image
    //    case .fortune:
    //      return STImages.clover.image
    case .pastLotto:
      return STImages.receipt.image
    case .map:
      return STImages.mapPin.image
    case .my:
      return STImages.user.image
    }
  }
}
