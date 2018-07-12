//
//  UIRootViewController.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/6/27.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import UIKit

class UIRootViewController: UIViewController {

    var videoViewController = UIVideoViewController()
         
    override func viewDidLoad() {
        super.viewDidLoad()
         
        self.addChildViewController(self.videoViewController)
        self.view.addSubview(self.videoViewController.view)
    }
    
    deinit {
        self.videoViewController.view.removeFromSuperview()
        self.videoViewController.removeFromParentViewController()
    }
    
    // Pass to child
    override var shouldAutorotate: Bool {
        return self.videoViewController.shouldAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.videoViewController.supportedInterfaceOrientations
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.videoViewController.viewWillTransition(to: size, with: coordinator)
    }
 
}

