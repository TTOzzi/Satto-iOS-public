//
//  LottoMarker.swift
//  Map
//
//  Created by ttozzi on 2/1/26.
//

import DesignSystem
import NMapsMap

public final class LottoMarker: NMFMarker {

  public var isSelected: Bool = false {
    didSet {
      updateIcon()
    }
  }

  public override init() {
    super.init()
    updateIcon()
    captionRequestedWidth = 75
  }

  private func updateIcon() {
    if isSelected {
      iconImage = NMFOverlayImage(image: STImages.pinLottoSelected.image)
    } else {
      iconImage = NMFOverlayImage(image: STImages.pinLotto.image)
    }
  }
}
