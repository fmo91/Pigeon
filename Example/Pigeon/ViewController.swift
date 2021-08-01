//
//  ViewController.swift
//  Pigeon
//
//  Created by fmo91 on 08/23/2020.
//  Copyright (c) 2020 fmo91. All rights reserved.
//

import UIKit
import Pigeon
import SwiftUI
import Combine

class ViewController: UIHostingController<ContentView> {
    
    init() {
        QueryCache.setGlobal(.userDefaults)
        super.init(rootView: ContentView())
    }
    
    @objc
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
