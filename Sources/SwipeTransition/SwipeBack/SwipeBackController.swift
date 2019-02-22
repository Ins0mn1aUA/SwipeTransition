//
//  SwipeBackController.swift
//  SwipeTransition
//
//  Created by Tatsuya Tanaka on 20171222.
//  Copyright © 2017年 tattn. All rights reserved.
//

import UIKit

@objcMembers
public final class SwipeBackController: NSObject {
    public var onStartTransition: ((UIViewControllerContextTransitioning) -> Void)?
    public var onFinishTransition: ((UIViewControllerContextTransitioning) -> Void)?
    fileprivate var isFirstPageOfPageViewController: (() -> Bool)?

    public var isEnabled: Bool {
        get { return context.isEnabled }
        set {
            context.isEnabled = newValue
            panGestureRecognizer.isEnabled = newValue
        }
    }

    fileprivate lazy var animator = SwipeBackAnimator(parent: self)
    fileprivate let context: SwipeBackContext
    fileprivate lazy var panGestureRecognizer = OneFingerDirectionalPanGestureRecognizer(direction: .horizontal, target: self, action: #selector(handlePanGesture(_:)))

    public required init(navigationController: UINavigationController) {
        context = SwipeBackContext(target: navigationController)
        super.init()

        panGestureRecognizer.delegate = self

        navigationController.view.addGestureRecognizer(panGestureRecognizer)
        setNavigationControllerDelegate(navigationController.delegate)

        // Prioritize the default edge swipe over the custom swipe back
        navigationController.interactivePopGestureRecognizer.map { panGestureRecognizer.require(toFail: $0) }
    }

    deinit {
        panGestureRecognizer.view?.removeGestureRecognizer(panGestureRecognizer)
    }

    public func setNavigationControllerDelegate(_ delegate: UINavigationControllerDelegate?) {
        context.navigationControllerDelegateProxy = NavigationControllerDelegateProxy(delegates: [self] + (delegate.map { [$0] } ?? []) )
    }

    public func observePageViewController(_ pageViewController: UIPageViewController, isFirstPage: @escaping () -> Bool) {
        let scrollView = pageViewController.view.subviews
            .lazy
            .flatMap { $0 as? UIScrollView }
            .first
        scrollView?.panGestureRecognizer.require(toFail: panGestureRecognizer)
        context.pageViewControllerPanGestureRecognizer = scrollView?.panGestureRecognizer
        isFirstPageOfPageViewController = isFirstPage
    }

    @objc private func handlePanGesture(_ recognizer: OneFingerDirectionalPanGestureRecognizer) {
        //NSLog("swipeback handlePanGesture %@", recognizer);
        switch recognizer.state {
        case .began:
            context.startTransition()
        case .changed:
            context.updateTransition(recognizer: recognizer)
        case .ended:
            if context.allowsTransitionFinish(recognizer: recognizer) {
                context.finishTransition()
            } else {
                fallthrough
            }
        case .cancelled:
            context.cancelTransition()
        default:
            break
        }
    }
}

extension SwipeBackController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
       // NSLog("swipeback .gestureRecognizerShouldBegin.gestureRecognizerShouldBegin")
        guard context.pageViewControllerPanGestureRecognizer == nil else {
          //  NSLog("swipeback gestureRecognizerShouldBegin.pageViewControllerPanGestureRecognizer")
            if gestureRecognizer != context.pageViewControllerPanGestureRecognizer,
                let isFirstPage = isFirstPageOfPageViewController?(), isFirstPage,
                let view = gestureRecognizer.view, panGestureRecognizer.translation(in: view).x > 0 {
             //   NSLog("swipeback gestureRecognizerShouldBegin.panGestureRecognizer true")
                return true
            }
           // NSLog("swipeback gestureRecognizerShouldBegin.panGestureRecognizer false")
            return false
        }
        //NSLog("swipeback gestureRecognizerShouldBegin.context.allowsTransitionStart")
        return context.allowsTransitionStart
    }
}

extension SwipeBackController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        //NSLog("swipeback interactiveTransitionIfNeeded")
        return operation == .pop && context.isEnabled && context.interactiveTransition != nil ? animator : nil
    }

    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
       // NSLog("swipeback interactiveTransitionIfNeeded %i", navigationController.viewControllers.count)
        return context.interactiveTransitionIfNeeded()
    }

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        //NSLog("swipeback navigationController willShow %i", navigationController.viewControllers.count)
        if animated, context.isEnabled {
            context.transitioning = true
        }
    }

    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        context.transitioning = false
        // NSLog("swipeback navigationController didShow %i", navigationController.viewControllers.count)
        panGestureRecognizer.isEnabled = navigationController.viewControllers.count > 1
    }
}
