//
//  SwipeBackNavigationController.swift
//  SwipeTransition
//
//  Created by Tatsuya Tanaka on 20171222.
//  Copyright © 2017年 tattn. All rights reserved.
//

import UIKit

open class SwipeBackNavigationController: UINavigationController {
    
    open override var childForStatusBarHidden: UIViewController? {
        return topViewController
    }
    
    open override var prefersStatusBarHidden: Bool {
        return topViewController?.prefersStatusBarHidden ?? false
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? .portrait
    }
    
    open override var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? false
    }
        
    open override func viewDidLoad() {
        super.viewDidLoad()
        swipeBack = SwipeBackController(navigationController: self)
    }
    
    open override func popViewController(animated: Bool) -> UIViewController? {
        if swipeBack?.isTransitionInProgress == false {
            // It mean that user did tap backButton (not swipe acton)
            let notificationName = Notification.Name(rawValue: "animateTabBarViewOnBackButtonPressed")
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
        
        return super.popViewController(animated: animated)
        
    }
}
