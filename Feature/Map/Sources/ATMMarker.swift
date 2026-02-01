//
//  ATMMarker.swift
//  Map
//
//  Created by ttozzi on 2/1/26.
//

import DesignSystem
import NMapsMap

public final class ATMMarker: NMFMarker {

  public override init() {
    super.init()
    iconImage = NMFOverlayImage(image: STImages.pinATM.image)
  }
}
