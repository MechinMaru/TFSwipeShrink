//
//  ExampleViewController.swift
//  TFSwipeShrink
//
//  Created by Taylor Franklin on 2/16/15.
//  Copyright (c) 2015 Taylor Franklin. All rights reserved.
//

import UIKit
import AVFoundation

class ExampleViewController: UIViewController {
    
    
    @IBOutlet weak var swipeShrinkView: TFSwipeShrinkView!
//    var moviePlayerController: AVPlayerViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
//        let videoURL = Bundle.main.url(forResource: "bayw-HD", withExtension: "mp4")
//        let player = AVPlayer(url: videoURL!)
//        moviePlayerController = AVPlayerViewController()
//        moviePlayerController.player = player
//        moviePlayerController.showsPlaybackControls = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func playMovie(sender: AnyObject) {
        let videoURL = Bundle.main.url(forResource: "bayw-HD", withExtension: "mp4")
        let player = AVPlayer(url: videoURL!)
        let floatingVC = FloatingViewController(avPlayer: player)
        
//        self.present(floatingVC, animated: true)
        
        if let delegate = UIApplication.shared.delegate {
            floatingVC.presentOnAppliactionDelegate(delegate)
        }
    }

}
