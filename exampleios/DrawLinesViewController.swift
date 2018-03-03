//
//  DrawLinesViewController.swift
//  exampleios
//
//  Created by Julian Bleecker on 3/3/18.
//

import Foundation
import UIKit

class DrawLinesViewController : UIViewController {
    
    
    var layer: CALayer {
        return self.view.layer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayer()
        
//        let wrapper = SwiftThatUsesWrapperForSwift()
//        wrapper.doSomething()
    }
    
    func setUpLayer() {
        layer.backgroundColor = UIColor.blue.cgColor
        layer.borderWidth = 100.0
        layer.borderColor = UIColor.red.cgColor
        layer.shadowOpacity = 0.7
        layer.shadowRadius = 10.0
    }
}
