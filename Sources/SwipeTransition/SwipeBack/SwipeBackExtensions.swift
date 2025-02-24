import UIKit

public extension UINavigationController {
    @objc var swipeBack: SwipeBackController? {
        get {
            return objc_getAssociatedObject(self, &AssocKey.swipeBack) as? SwipeBackController
        }
        set {
            objc_setAssociatedObject(self, &AssocKey.swipeBack, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
