//
//  UIView+pinEdges.swift
//  PGPro
//
//  Source: https://www.hackingwithswift.com/example-code/uikit/how-to-make-a-uiview-fill-the-screen-using-auto-layout-anchors
//

import UIKit

extension UIView {
    func pinEdges(to other: UIView) {
        leadingAnchor.constraint(equalTo: other.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: other.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: other.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: other.bottomAnchor).isActive = true
    }
}
