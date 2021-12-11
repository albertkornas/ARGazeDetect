//
//  ViewController.swift
//  ARGazeDetect
//
//  Created by Albert Kornas on 12/10/21.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {

    var faceAnchorsAndContentControllers: [ARFaceAnchor: VirtualContentController] = [:]
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        DispatchQueue.main.async {
            let contentController = GazeDetector()
            if node.childNodes.isEmpty, let contentNode = contentController.renderer(renderer, nodeFor: faceAnchor) {
                node.addChildNode(contentNode)
                self.faceAnchorsAndContentControllers[faceAnchor] = contentController
            }
        }
    }
    
    public var positionLabel: UILabel = UILabel(frame: CGRect(x: 100, y: 100, width: 150, height: 100))
    
    @IBOutlet var sceneView: ARSCNView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        positionLabel.text = "Vision location"
        sceneView.addSubview(positionLabel)
        
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
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
            //self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
            print("Failure \(errorMessage)")
        }
    }
    
    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        }
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        faceAnchorsAndContentControllers.removeAll()
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
            self.positionLabel.frame = CGRect(x: CGFloat(positionX) * self.sceneView.frame.width, y: CGFloat(positionY) * self.sceneView.frame.height, width: 150, height: 100)
        }
        contentController.renderer(renderer, didUpdate: contentNode, for: anchor)
    }

}


