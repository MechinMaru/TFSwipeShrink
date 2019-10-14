//
//  TFSwipeShrinkView.swift
//  TFSwipeShrink
//
//  Created by Taylor Franklin on 2/16/15.
//  Copyright (c) 2015 Taylor Franklin. All rights reserved.
//

import UIKit

class TFSwipeShrinkView: UIView, UIGestureRecognizerDelegate {

    var initialCenter: CGPoint?
    var finalCenter: CGPoint?
    var initialSize: CGSize?
    var finalSize: CGSize?
    var firstX: CGFloat = 0, firstY: CGFloat = 0
    var aspectRatio: CGFloat = 0.5625
    
    var finalTranslateX: CGFloat!
    var finalTranslateY: CGFloat!
    var finalScale: CGFloat = 0.5
    var panGesture: UIPanGestureRecognizer!
    var tapGesture: UITapGestureRecognizer!
    
    // Should be called when making view programmatically
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initGestures()
    }

    // Should be called when creating view from storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initGestures()
    }
    
    func initGestures() {
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panning(panGesture:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(tapGesture:)))
        tapGesture.numberOfTapsRequired = 1
        self.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        
    }
    
    /// Method to set up initial and final positions of view
    func configureSizeAndPosition(parentViewFrame: CGRect) {
        
        self.initialCenter = self.center
        self.finalCenter = CGPoint(x: parentViewFrame.size.width - parentViewFrame.size.width/4, y: parentViewFrame.size.height - (self.frame.size.height/4) - 2)
        
        initialSize = self.frame.size
        finalSize = CGSize(width: parentViewFrame.size.width/2 - 10, height: (parentViewFrame.size.width/2 - 10) * aspectRatio)
        
        // Set common range totals once
        finalTranslateX = self.finalCenter!.x - panGesture.view!.frame.size.width / 2
        finalTranslateY = self.finalCenter!.y - panGesture.view!.frame.size.height
    }
    
    
    func progressFromY(_ y: CGFloat) -> CGFloat {
        var progress = y / finalTranslateY
        if isMinimized {
            progress *= -1
        }
        if progress > 1 {
            progress = 1
        }else if progress < 0 {
            progress = 0
        }
        if isMinimized {
            progress = 1 - progress
        }
        return progress
    }
    
    var isMinimized = false
    @objc func panning(panGesture: UIPanGestureRecognizer) {
        
        let gestureState = panGesture.state

        if gestureState == UIGestureRecognizer.State.began || gestureState == UIGestureRecognizer.State.changed  {
            let progress = self.progressFromY(panGesture.translation(in: self.superview!).y)

            panGesture.view?.transform = CGAffineTransform(translationX: finalTranslateX * progress, y:  finalTranslateY * progress)
                .scaledBy(x: 1 - (0.5 * progress), y: 1 - (0.5 * progress))
            
        } else if gestureState == UIGestureRecognizer.State.ended {
            let progress = self.progressFromY(panGesture.velocity(in: self.superview!).y)

            self.isUserInteractionEnabled = false
            let isToTop = progress <= 0.5
            
            UIView.animate(withDuration: 0.4, animations: {
                panGesture.view?.transform = isToTop
                    ? CGAffineTransform.identity
                    : CGAffineTransform(translationX: self.finalTranslateX,
                                        y: self.finalTranslateY)
                        .scaledBy(x: self.finalScale, y: self.finalScale)
            }, completion: {(done: Bool) in
                self.isUserInteractionEnabled = true
                self.isMinimized = !isToTop
            })
        }
        
    }
    
    @objc func tapped(tapGesture: UITapGestureRecognizer) {
        if self.isMinimized {
            self.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.4, animations: {
                tapGesture.view?.transform = CGAffineTransform.identity
            }, completion: {(done: Bool) in
                self.isUserInteractionEnabled = true
                self.isMinimized = false
            })
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGesture && otherGestureRecognizer == panGesture {
            return false
        }else if gestureRecognizer == panGesture && otherGestureRecognizer == tapGesture {
            return false
        }
        return true
    }

}
