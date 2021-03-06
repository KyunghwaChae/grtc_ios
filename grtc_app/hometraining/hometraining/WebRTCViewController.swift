//
//  WebRTCViewController.swift
//  hometraining
//
//  Created by snlcom on 2021/09/19.
//

import Foundation
import UIKit
import WebRTC
import grtc

class WebRTCViewController: UIViewController, MediaServerProxyObserver {

    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView1: UIView!
    @IBOutlet weak var remoteVideoView2: UIView!
    @IBOutlet weak var remoteVideoView3: UIView!
    @IBOutlet weak var remoteVideoView4: UIView!
    @IBOutlet weak var remoteVideoView5: UIView!
    @IBOutlet weak var remoteVideoView6: UIView!
    @IBOutlet weak var remoteVideoView7: UIView!
    
    
    public var roomid: Int32!
    public var isTeacher: Bool!
    public var code: String!
    public var width: Int32!
    public var height: Int32!
    public var bitrate: Int32!
    public var codes: [String]! = [String]()
    
    private var cameraOn: Bool = true
    private var micOn: Bool = true
    
    private var hometraining: MediaServerProxy! = nil
    private var remoteRenderers: [RTCVideoRenderer]! = [RTCVideoRenderer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view."
        definesPresentationContext = true
        self.internalStart(false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.internalStop()
    }
    
    private func internalStart(_ bForceJoin: Bool) {
        #if arch(arm64)
        let localRenderer = RTCMTLVideoView(frame: self.localVideoView.frame)
        let remoteRenderer1 = RTCMTLVideoView(frame: self.remoteVideoView1.frame)
        let remoteRenderer2 = RTCMTLVideoView(frame: self.remoteVideoView2.frame)
        let remoteRenderer3 = RTCMTLVideoView(frame: self.remoteVideoView3.frame)
        let remoteRenderer4 = RTCMTLVideoView(frame: self.remoteVideoView4.frame)
        let remoteRenderer5 = RTCMTLVideoView(frame: self.remoteVideoView5.frame)
        let remoteRenderer6 = RTCMTLVideoView(frame: self.remoteVideoView6.frame)
        let remoteRenderer7 = RTCMTLVideoView(frame: self.remoteVideoView7.frame)
        localRenderer.videoContentMode = .scaleAspectFill
        remoteRenderer1.videoContentMode = .scaleAspectFill
        remoteRenderer2.videoContentMode = .scaleAspectFill
        remoteRenderer3.videoContentMode = .scaleAspectFill
        remoteRenderer4.videoContentMode = .scaleAspectFill
        remoteRenderer5.videoContentMode = .scaleAspectFill
        remoteRenderer6.videoContentMode = .scaleAspectFill
        remoteRenderer7.videoContentMode = .scaleAspectFill
        #else
        let localRenderer = RTCEAGLVideoView(frame: self.localVideoView.frame)
        let remoteRenderer1 = RTCEAGLVideoView(frame: self.remoteVideoView1.frame)
        let remoteRenderer2 = RTCEAGLVideoView(frame: self.remoteVideoView2.frame)
        let remoteRenderer3 = RTCEAGLVideoView(frame: self.remoteVideoView3.frame)
        let remoteRenderer4 = RTCEAGLVideoView(frame: self.remoteVideoView4.frame)
        let remoteRenderer5 = RTCEAGLVideoView(frame: self.remoteVideoView5.frame)
        let remoteRenderer6 = RTCEAGLVideoView(frame: self.remoteVideoView6.frame)
        let remoteRenderer7 = RTCEAGLVideoView(frame: self.remoteVideoView7.frame)
        #endif
        remoteRenderers.append(remoteRenderer1)
        remoteRenderers.append(remoteRenderer2)
        remoteRenderers.append(remoteRenderer3)
        remoteRenderers.append(remoteRenderer4)
        remoteRenderers.append(remoteRenderer5)
        remoteRenderers.append(remoteRenderer6)
        remoteRenderers.append(remoteRenderer7)


        self.embedView(localRenderer, into: self.localVideoView)
        self.embedView(remoteRenderer1, into: self.remoteVideoView1)
        self.embedView(remoteRenderer2, into: self.remoteVideoView2)
        self.embedView(remoteRenderer3, into: self.remoteVideoView3)
        self.embedView(remoteRenderer4, into: self.remoteVideoView4)
        self.embedView(remoteRenderer5, into: self.remoteVideoView5)
        self.embedView(remoteRenderer6, into: self.remoteVideoView6)
        self.embedView(remoteRenderer7, into: self.remoteVideoView7)

        self.hometraining = MediaServerProxy(localRenderer, remoteRenderers, self.codes, "https://webrtc.seers-visual-system.link", self.code, self.roomid, self.width, self.height, 30, self.bitrate, self.isTeacher, bForceJoin, self)
        self.hometraining.Start()
    }
    
    private func internalStop() {
        self.hometraining.Stop()
    }
    
    private func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }
    
    @IBAction func onCameraClick(_ sender: UIButton) {
        if let proxy = self.hometraining {
            if self.cameraOn {
                proxy.enableVideo(false)
                sender.setImage(#imageLiteral(resourceName: "camera_off"), for: .normal)
                self.cameraOn = false
            } else {
                proxy.enableVideo(true)
                sender.setImage(#imageLiteral(resourceName: "camera_on"), for: .normal)
                self.cameraOn = true
            }
        }
    }
    
    @IBAction func onMicClick(_ sender: UIButton) {
        if let proxy = self.hometraining {
            if self.micOn {
                proxy.enableAudio(false)
                sender.setImage(#imageLiteral(resourceName: "mic_off"), for: .normal)
                self.micOn = false
            } else {
                proxy.enableAudio(true)
                sender.setImage(#imageLiteral(resourceName: "mic_on"), for: .normal)
                self.micOn = true
            }
        }

    }
    
    func onCreatedRoom(_ sessionId: Int64!, _ publishId: Int64!) {
        DispatchQueue.main.async {
            let message = "Room is Created"
            let alert = UIAlertController(title: "onCreatedRoom", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            //alert.dismiss(animated: true)
        }
    }
    
    func onJoinedRoom(_ sessionId: Int64!, _ publishId: Int64!) {
        DispatchQueue.main.async {
            let message = "Joined to Room"
            let alert = UIAlertController(title: "onJoinedRoom", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            //alert.dismiss(animated: true)
        }
    }
    
    func onLeaveRoom(_ publishId: Int64!, _ code: String!) {
        DispatchQueue.main.async {
            let message = "\(code!) leaved the room"
            let alert = UIAlertController(title: "onLeaveRoom", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            //alert.dismiss(animated: true)
        }
    }
    
    func onPublish(_ publishId: Int64!, _ code: String!) {
        DispatchQueue.main.async {
            let message = "\(code!) start publishing"
            let alert = UIAlertController(title: "onPublish", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            //alert.dismiss(animated: true)
        }
    }
    
    func onUnpublish(_ publishId: Int64!, _ code: String!) {
        DispatchQueue.main.async {
            let message = "\(code!) stop publishing"
            let alert = UIAlertController(title: "onUnpublish", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            //alert.dismiss(animated: true)
        }
    }
    
    func onVideo(_ code: String!, _ enable: Bool!) {
        
        DispatchQueue.main.async {
            let message = "\(code!)'s' video is " + (enable ? "enabled" : "disabled")
            let alert = UIAlertController(title: "onVideo", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            //alert.dismiss(animated: true)
        }
    }
    
    func onExistUser(_ code: String!) {
        
        DispatchQueue.main.async {
            let message = "\(code!) is already join in this room"
            let alert = UIAlertController(title: "onExistUser", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            //alert.dismiss(animated: true)
            
            self.internalStop()
            self.internalStart(true)
        }
    }
    
    func onExitUser() {
        DispatchQueue.main.async {
            let message = "Same User login through Other Device"
            let alert = UIAlertController(title: "onExistUser", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            self.presentingViewController?.dismiss(animated: true)
        }
    }

}
