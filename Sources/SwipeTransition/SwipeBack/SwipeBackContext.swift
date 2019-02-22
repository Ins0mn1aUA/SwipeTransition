//
//  SwipeBackContext.swift
//  SwipeTransition
//
//  Created by Tatsuya Tanaka on 20171227.
//  Copyright © 2017年 tattn. All rights reserved.
//

import UIKit

final class SwipeBackContext: Context<UINavigationController>, ContextType {
    // Delegate Proxies (strong reference)
    var navigationControllerDelegateProxy: NavigationControllerDelegateProxy? {
        didSet {
            target?.delegate = navigationControllerDelegateProxy
        }
    }

    weak var pageViewControllerPanGestureRecognizer: UIPanGestureRecognizer?

    override var allowsTransitionStart: Bool {
        guard let navigationController = target else { return false }
       // NSLog("pageViewControllerPanGestureRecognizer %i and %i", navigationController.viewControllers.count > 1, super.allowsTransitionStart);
        return navigationController.viewControllers.count > 1 && super.allowsTransitionStart
    }

    /*allowsTransitionFinish <UILayoutContainerView: 0x1069566e0; frame = (0 0; 1366 1024); autoresize = W+H; gestureRecognizers = <NSArray: 0x28046eca0>; layer = <CALayer: 0x280a537e0>>*/

    func allowsTransitionFinish(recognizer: UIPanGestureRecognizer) -> Bool {
        //NSLog("allowsTransitionFinish %@", targetView!);
        guard let view = targetView else { return false }
        //NSLog("allowsTransitionFinish %i", recognizer.velocity(in: view).x > 0);
        return recognizer.velocity(in: view).x > 0
    }

    func didStartTransition() {
        target?.popViewController(animated: true)
    }

    func updateTransition(recognizer: UIPanGestureRecognizer) {
        guard let view = targetView, isEnabled else { return }
        let translation = recognizer.translation(in: view)
        //NSLog("updateTransition %f and %f", translation.x, view.bounds.width);
        interactiveTransition?.update(value: translation.x, maxValue: view.bounds.width)
    }
}
