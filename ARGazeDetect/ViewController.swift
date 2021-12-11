//
//  ViewController.swift
//  ARGazeDetect
//
//  Created by Albert Kornas on 12/10/21.
//

import UIKit
import ARKit
import AVKit
import SceneKit

class ViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {

    var faceAnchorsAndContentControllers: [ARFaceAnchor: VirtualContentController] = [:]
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        DispatchQueue.main.async {
            let contentController = GazeDetector()
            if node.childNodes.isEmpty, let contentNode = contentController.renderer(renderer, nodeFor: faceAnchor) {
                node.addChildNode(contentNode)
                self.faceAnchorsAndContentControllers[faceAnchor] = contentController
            }
        }
    }
    var avPlayer: AVPlayer!
    
    public var positionLabel: UILabel = UILabel(frame: CGRect(x: 100, y: 100, width: 150, height: 100))
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        positionLabel.text = "Vision location"
        sceneView.addSubview(positionLabel)
        //sceneView.scene.background.contents = UIColor.clear
        
        let filepath: String? = Bundle.main.path(forResource: "ad", ofType: "mp4")
               let fileURL = URL.init(fileURLWithPath: filepath!)

               avPlayer = AVPlayer(url: fileURL)
        
               let avPlayerController = AVPlayerViewController()
               avPlayerController.player = avPlayer
               avPlayerController.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)

               // Turn on video controlls
               avPlayerController.showsPlaybackControls = true

               // play video
               avPlayerController.player?.play()
               self.view.addSubview(avPlayerController.view)
               self.addChild(avPlayerController)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Disable screen sleeping
        UIApplication.shared.isIdleTimerDisabled = true
        // "Reset" to run the AR session for the first time.
        beginTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.positionLabel.text = "AR Session Error - \(errorMessage)"
        }
    }
    
    /// - Tag: ARFaceTrackingSetup
    func beginTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        }
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let contentController = faceAnchorsAndContentControllers[faceAnchor],
            let contentNode = contentController.contentNode else {
            return
        }
        
        DispatchQueue.main.async {
            let positionX = contentController.visionPosition[0]+0.5
            let positionY = 1-(contentController.visionPosition[1]+0.5)
            if positionX.magnitude <= 0.4 || positionX.magnitude >= 0.6 {
                let alert = UIAlertController(title: "Ad Paused", message: "You must watch the advertisement to proceed.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default))
                self.present(alert, animated: true)
                self.avPlayer.pause()
            } else {
                self.avPlayer.play()
            }
            self.positionLabel.frame = CGRect(x: CGFloat(positionX) * self.sceneView.frame.width, y: CGFloat(positionY) * self.sceneView.frame.height, width: 150, height: 100)
        }
        contentController.renderer(renderer, didUpdate: contentNode, for: anchor)
    }
}
