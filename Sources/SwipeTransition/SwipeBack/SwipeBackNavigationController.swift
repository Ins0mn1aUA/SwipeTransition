//
//  SwipeBackNavigationController.swift
//  SwipeTransition
//
//  Created by Tatsuya Tanaka on 20171222.
//  Copyright © 2017年 tattn. All rights reserved.
//

import UIKit

open class SwipeBackNavigationController: UINavigationController {
    
    public var maxWidth:CGFloat = 0
    
    open override var childForStatusBarHidden: UIViewController? {
        return topViewController
    }
    
    open override var prefersStatusBarHidden: Bool {
        return topViewController?.prefersStatusBarHidden ?? false
    }
        
    open override func viewDidLoad() {
        super.viewDidLoad()
        swipeBack = SwipeBackController(navigationController: self)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
//
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard let window = view.superview else { return }
        if (maxWidth > 0) {
            let paddings:CGFloat = isRealIPad() ? 64 : isPortrait(from: self.view) ? 0 : 32
            let horizontalPadding: CGFloat = max(paddings, (view.frame.width - maxWidth)/2)
            let screenWidth = window.bounds.width
            let newWidth = min(maxWidth, screenWidth)
            
            view.bounds.size.width = newWidth
            view.center.x = screenWidth / 2
            if (!isPortrait(from: self.view)) {
                view.bounds.size.height = window.bounds.height - 16
                view.frame.origin.y = 16
            } else {
                view.bounds.size.height = view.bounds.size.height
                view.frame.origin.y = 0
            }
           
            
        }
    }
    
    func isPortrait(from view: UIView) -> Bool {
        return view.frame.size.width < view.frame.size.height
    }
    
    func isRealIPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
