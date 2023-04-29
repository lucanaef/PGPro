//
//  ColorfulIconLabelStyle.swift
//
//  Source: https://gist.github.com/Luca1719/4beb952c03cd5789c19c2017e89436ea#file-colorfuliconlabelstyle-swift
//

import Foundation
import SwiftUI

struct ColorfulIconLabelStyle: LabelStyle {
    var color: Color
    var size: CGFloat = 1.0

    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .imageScale(.small)
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 7 * size).frame(width: 28 * size, height: 28 * size).foregroundColor(color))
        }
    }
}
