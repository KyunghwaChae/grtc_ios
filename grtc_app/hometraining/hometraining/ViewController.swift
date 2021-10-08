//
//  ViewController.swift
//  hometraining
//
//  Created by snlcom on 2021/09/19.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var roomid: UITextField!
    @IBOutlet weak var participantType: UISegmentedControl!
    @IBOutlet weak var participantCode: UITextField!
    @IBOutlet weak var width: UITextField!
    @IBOutlet weak var height: UITextField!
    @IBOutlet weak var bitrate: UITextField!
    @IBOutlet weak var participantCodes: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view."
        roomid.text = "123456"
        participantType.selectedSegmentIndex = 1
        participantCode.text = "aaa"
        width.text = "640"
        height.text = "480"
        bitrate.text = "1"
        participantCodes.text = "teacher"
//        participantCodes.text = "aaa"
    }

    
    @IBAction func onChangeParticipantType(_ sender: Any) {
        switch participantType.selectedSegmentIndex {
        case 0:
            participantCode.text = "teacher"
            bitrate.text = "2"
            participantCodes.text = "aaa;bbb;ccc;ddd;eee;fff;ggg"
//            participantCodes.text = "aaa"
        case 1:
            participantCode.text = "aaa"
            bitrate.text = "1"
            participantCodes.text = "teacher"
        default:
            break
        }
    }

    @IBAction func onJoin(_ sender: UIButton) {
        performSegue(withIdentifier: "showWebRTCView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let webRTCVC = segue.destination as! WebRTCViewController
        if let roomid = self.roomid.text {
            webRTCVC.roomid = Int32(roomid)
        }
        if participantType.selectedSegmentIndex == 0 {
            webRTCVC.isTeacher = true
        } else {
            webRTCVC.isTeacher = false
        }
        if let code = self.participantCode.text {
            webRTCVC.code = code
        }
        if let height = self.height.text {
            webRTCVC.height = Int32(height)
        }
        if let width = self.width.text {
            webRTCVC.width = Int32(width)
        }
        if let bitrate = self.bitrate.text {
            webRTCVC.bitrate = Int32(bitrate)
        }
        if let codes = self.participantCodes.text {
            webRTCVC.codes = codes.components(separatedBy: ";")
        }
        
        
        
    }
}

