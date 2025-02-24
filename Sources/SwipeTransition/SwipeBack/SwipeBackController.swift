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
    public var onWillStartTransition: (() -> Void) = { }
    public var onStartTransition: ((UIViewControllerContextTransitioning) -> Void)?
    public var onFinishTransition: ((UIViewControllerContextTransitioning) -> Void)?
    private var shouldBeginSwipeTransition: ((UIGestureRecognizer) -> Bool)?

    public var radius:CGFloat = 0 {
        didSet {
            updateCorners()
        }
    }
    
    public var corners:UIRectCorner = .allCorners {
        didSet {
            updateCorners()
        }
    }
    
    public var cornersDisabled:Bool = true {
        didSet {
            updateCorners()
        }
    }
    
    private func updateCorners() {
        if (!cornersDisabled) {
            if let view = self.navigationController?.view {
                roundCorners(corners, radius: radius, view: view)
            }
        }
    }
    
    public var fakeGrabberView: UIView? {
        didSet {
            oldValue?.removeFromSuperview() // Видаляємо старий fakeGrabberView, якщо він існував
            
            guard let fakeGrabberView = fakeGrabberView else { return } // Якщо нове значення nil — просто виходимо
            
            fakeGrabberView.translatesAutoresizingMaskIntoConstraints = false
            self.navigationController?.view.addSubview(fakeGrabberView)
            
            if let view = self.navigationController?.view {
                NSLayoutConstraint.activate([
                    fakeGrabberView.topAnchor.constraint(equalTo: view.topAnchor),
                    fakeGrabberView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    fakeGrabberView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    fakeGrabberView.heightAnchor.constraint(equalToConstant: 10)
                ])
            }
        }
    }
    
    public var isEnabled: Bool {
        get { return context.isEnabled }
        set {
            context.isEnabled = newValue
            
            switch newValue {
            case true where panGestureRecognizer.view == nil:
                navigationController?.view.addGestureRecognizer(panGestureRecognizer)
            case true:
                // If already added gesture, do nothing
                break
            case false:
                panGestureRecognizer.view?.removeGestureRecognizer(panGestureRecognizer)
            }
        }
    }

    private lazy var animator = SwipeBackAnimator(parent: self)
    let context: SwipeBackContext
    public lazy var panGestureRecognizer = OneFingerDirectionalPanGestureRecognizer(direction: .right, target: self, action: #selector(handlePanGesture(_:)))
    private weak var navigationController: UINavigationController?

    public required init(navigationController: UINavigationController) {
        context = SwipeBackContext(target: navigationController)
        super.init()
        
        context.didStartTransitionHandler = { [weak self] in
            self?.onWillStartTransition()
        }

        self.navigationController = navigationController
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

    public func observe(viewController: UIViewController, shouldBeginSwipe: @escaping (UIGestureRecognizer) -> Bool) {
        let scrollView = viewController.view.subviews
            .lazy
            .compactMap { $0 as? UIScrollView }
            .first
        scrollView?.panGestureRecognizer.require(toFail: panGestureRecognizer)
        context.pageViewControllerGestureRecognizer = scrollView?.panGestureRecognizer
        shouldBeginSwipeTransition = shouldBeginSwipe
    }
    
    public func observe(scrollView: UIScrollView, shouldBeginSwipe: @escaping (UIGestureRecognizer) -> Bool) {
        scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        context.pageViewControllerGestureRecognizer = scrollView.panGestureRecognizer
        shouldBeginSwipeTransition = shouldBeginSwipe
    }
    
    public func observe(view: UIView, shouldBeginSwipe: @escaping (UIGestureRecognizer) -> Bool) {
        view.gestureRecognizers?.first?.require(toFail: panGestureRecognizer)
        context.pageViewControllerGestureRecognizer = view.gestureRecognizers?.first
        shouldBeginSwipeTransition = shouldBeginSwipe
    }

    @objc private func handlePanGesture(_ recognizer: OneFingerDirectionalPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            navigationController?.topViewController?.view.endEditing(true)
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
        guard context.pageViewControllerGestureRecognizer == nil else {
            if gestureRecognizer != context.pageViewControllerGestureRecognizer,
                let shoudBeginSwipe_ = shouldBeginSwipeTransition?(gestureRecognizer), shoudBeginSwipe_,
                let view = gestureRecognizer.view, panGestureRecognizer.translation(in: view).x > 0 {
                return true
            }
            return false
        }
        return context.allowsTransitionStart
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UISlider)
    }
    
    @objc func roundCorners(_ corners: UIRectCorner, radius: CGFloat, view:UIView) {
        if (view.layer.cornerRadius == radius && view.layer.maskedCorners == self.cornersToMask(corners)) {
            return;
        }
        view.layer.cornerRadius = radius
        view.layer.masksToBounds = true
        view.layer.maskedCorners = self.cornersToMask(corners)
    }
    
    @objc func cornersToMask(_ corners: UIRectCorner) -> CACornerMask {
        if (corners.contains(.allCorners)) {
            return [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if (corners.contains([.topRight, .topLeft])) {
            return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if (corners.contains([.bottomLeft, .bottomRight])) {
            return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if (corners.contains([.topLeft, .bottomLeft])) {
            return [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        } else if (corners.contains([.topRight, .bottomRight])) {
            return [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        } else if (corners.contains(.topRight)) {
            return [.layerMaxXMinYCorner]
        } else if (corners.contains(.topLeft)) {
            return [.layerMinXMinYCorner]
        } else if (corners.contains(.bottomLeft)) {
            return [.layerMinXMaxYCorner]
        } else if (corners.contains(.bottomRight)) {
            return [.layerMaxXMaxYCorner]
        }
        return []
    }
}

extension SwipeBackController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return operation == .pop && context.isEnabled && context.interactiveTransition != nil ? animator : nil
    }

    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return context.interactiveTransitionIfNeeded()
    }

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if animated, context.isEnabled {
            context.transitioning = true
        }
    }

    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        context.transitioning = false
        panGestureRecognizer.isEnabled = navigationController.viewControllers.count > 1
    }
}
