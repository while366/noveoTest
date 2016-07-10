

import UIKit


class AIManager {
    
    static let aiManager = AIManager()
    
    private var activityIndicator: UIActivityIndicatorView?
    
    private let style = UIActivityIndicatorViewStyle.WhiteLarge
    private let color = UIColor.whiteColor()
    private let backgroundColor = UIColor(white: 0.0, alpha: 0.20)
    
    var state: Bool {
        get {
           return activityIndicator != nil
        }
    }
    
    func addActivityIndicator(view: UIView, style: UIActivityIndicatorViewStyle?, color: UIColor?, backgroundColor: UIColor?) {
        guard activityIndicator == nil else { return }
        activityIndicator = UIActivityIndicatorView(frame: view.bounds)
        activityIndicator!.activityIndicatorViewStyle = (style != nil) ? style! : self.style
        activityIndicator!.color = (color != nil) ? color! : self.color
        activityIndicator!.backgroundColor = (backgroundColor != nil) ? backgroundColor! : self.backgroundColor
        activityIndicator!.startAnimating()
        view.addSubview(activityIndicator!)
    }
    
    func removeActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()) { 
            guard self.activityIndicator != nil else { return }
            self.activityIndicator!.removeFromSuperview()
            self.activityIndicator = nil
        }
    }
}