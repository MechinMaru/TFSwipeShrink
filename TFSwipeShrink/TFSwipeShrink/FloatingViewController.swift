//
//  FloatingViewController.swift
//  TFSwipeShrink
//
//  Created by MECHIN on 10/16/19.
//  Copyright © 2019 Taylor Franklin. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class PassThroughView: UIView {
    
    var isAllowPassthrough = false
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if !isAllowPassthrough {
            return true
        }
        
        for subview in subviews {
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
    
    weak var touchDelegate: UIView? = nil

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = super.hitTest(point, with: event) {
            return view
        }

        if isAllowPassthrough {
            return touchDelegate?.hitTest(point, with: event)
        }
        
        return nil
    }
}

class FloatingViewController: UIViewController {
    
    convenience init() {
        self.init(avPlayer: nil)
    }

    init(avPlayer: AVPlayer?) {
        super.init(nibName: nil, bundle: nil)
        self.moviePlayerController.player = avPlayer
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    var minimizedVideoRatio: CGFloat = 0.5
    var verticalMargin: CGFloat = 70
    var horizontalMargin: CGFloat = 10
    var backdropOpacity: CGFloat = 0.8
    var presentAnimationDuration: TimeInterval = 0.3
    var passthroughView: PassThroughView!

    
    var isMinimized: Bool {
        return lastDropPoint != CGPoint.zero
    }

    private var moviePlayerController: AVPlayerViewController = AVPlayerViewController()
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    
    private var lastDropPoint = CGPoint.zero {
        didSet {
            moviePlayerController.showsPlaybackControls = lastDropPoint == CGPoint.zero
            passthroughView.isAllowPassthrough = lastDropPoint != CGPoint.zero
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
        
        moviePlayerController.view.translatesAutoresizingMaskIntoConstraints = false
        moviePlayerController.showsPlaybackControls = true
        
        if #available(iOS 11.0, *) {
            moviePlayerController.exitsFullScreenWhenPlaybackEnds = true
        }
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(backdropOpacity)
        self.view.addSubview(moviePlayerController.view)
        
        NSLayoutConstraint.activate([
            moviePlayerController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            moviePlayerController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            moviePlayerController.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            moviePlayerController.view.heightAnchor.constraint(equalTo: moviePlayerController.view.widthAnchor, multiplier:  9 / 16)
        ])
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panning(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        moviePlayerController.view.addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.numberOfTapsRequired = 1
        moviePlayerController.view.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
    }
    
    override func loadView() {
        self.passthroughView = PassThroughView()
        self.view = passthroughView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        passthroughView.touchDelegate = self.presentingViewController?.view
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying(note:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        moviePlayerController.player?.play()
    }
    
    
    @objc func panning(_ panGesture: UIPanGestureRecognizer) {
        let videoHeight = self.view.frame.size.width / 16 * 9
                
        switch panGesture.state {
        case .began, .changed:
            let translation = panGesture.translation(in: self.view)
            let progressY = abs(translation.y) / videoHeight
            let progressX = abs(translation.x) / videoHeight
            var topProgress = progressY > progressX ? progressY : progressX
            
            if self.isMinimized {
                topProgress = 1
            }
            
            
            if topProgress > 1 {
                topProgress = 1
            }else if topProgress < 0 {
                topProgress = 0
            }
            
            moviePlayerController.view.transform = CGAffineTransform(translationX: lastDropPoint.x + translation.x,
                                                                     y: lastDropPoint.y + translation.y)
                .scaledBy(x: 1 - (topProgress * (1 - minimizedVideoRatio)), y:  1 - (topProgress * (1 - minimizedVideoRatio)))
            
            if !self.isMinimized {
                self.view.backgroundColor = UIColor.black.withAlphaComponent(backdropOpacity - (topProgress * backdropOpacity))
            }
            
            break
        case .ended:
            let minimizedVideoWidth = self.view.frame.size.width * self.minimizedVideoRatio
            let minimizedVideoHeight = videoHeight * self.minimizedVideoRatio
        
            var dropPointX = self.lastDropPoint.x
            var dropPointY = self.lastDropPoint.y
            var isDismiss = false
            
            let velocity = panGesture.velocity(in: self.view)
            
            let minusVideoHeight = videoHeight * -1
            if velocity.x < minusVideoHeight {
                dropPointX = (((self.view.frame.size.width - minimizedVideoWidth) / 2) * -1) + self.horizontalMargin
            }else if velocity.x > videoHeight {
                dropPointX = ((self.view.frame.size.width - minimizedVideoWidth) / 2) - self.horizontalMargin
            }
            
            if velocity.y < minusVideoHeight {
                dropPointY = (((self.view.frame.size.height - minimizedVideoHeight) / 2) * -1) + self.verticalMargin
            }else if velocity.y > videoHeight {
                dropPointY = ((self.view.frame.size.height - minimizedVideoHeight) / 2) - self.verticalMargin
            }
            
            if self.isMinimized {
                if dropPointX == self.lastDropPoint.x && dropPointY == self.lastDropPoint.y {
                    dropPointX += velocity.x
                    dropPointY += velocity.y
                    
                    if abs(dropPointX) > abs(self.lastDropPoint.x) + videoHeight
                        || abs(dropPointY) > abs(self.lastDropPoint.y) + videoHeight {
                        isDismiss = true
                    }
                    
                    if !isDismiss {
                        dropPointX = self.lastDropPoint.x
                        dropPointY = self.lastDropPoint.y
                    }
                }
            }else{
                if dropPointX == 0 || dropPointY == 0 {
                    dropPointX = 0.0
                    dropPointY = 0.0
                }
            }
            
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 5,
                           options: .curveEaseInOut,
                           animations: {
                if dropPointX == 0 && dropPointY == 0  {
                    self.moviePlayerController.view.transform = .identity
                    self.view.backgroundColor = UIColor.black.withAlphaComponent(self.backdropOpacity)
                }else{
                    self.moviePlayerController.view.transform = CGAffineTransform(translationX: dropPointX, y: dropPointY)
                        .scaledBy(x: self.minimizedVideoRatio, y: self.minimizedVideoRatio)
                    self.view.backgroundColor = UIColor.clear
                }
            }, completion: { (_) in
                if isDismiss {
                    self.dismiss(animated: false)
                }else {
                    self.lastDropPoint = CGPoint(x: dropPointX, y: dropPointY)
                }
            })
            break
        default:
            break
        }
    }
    
    @objc func tapped(_ tapGesture: UITapGestureRecognizer) {
        if self.isMinimized {
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 5,
                           options: .curveEaseInOut,
                           animations: {
                self.moviePlayerController.view.transform = .identity
                self.view.backgroundColor = UIColor.black.withAlphaComponent(self.backdropOpacity)
            }, completion: { (_) in
                self.lastDropPoint = CGPoint.zero
            })
        }
    }
    

    @objc func playerDidFinishPlaying(note: NSNotification) {
        self.dismiss(animated: true)
    }
    
    func presentOnAppliactionDelegate(_ delegate: UIApplicationDelegate) {
        guard let windowMaybe = delegate.window,
            let window = windowMaybe,
            var vc = window.rootViewController else { return }

        while let topVC = vc.presentedViewController {
            vc = topVC
        }
        
        vc.present(self, animated: true)
    }

}

extension FloatingViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGesture && otherGestureRecognizer == panGesture {
            return false
        }else if gestureRecognizer == panGesture && otherGestureRecognizer == tapGesture {
            return false
        }
        return true
    }
    
}
