//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

public protocol IPluginHandleWebRTCCallbacks : IMediaServerCallbacks {
    func onSuccess(_ obj: JSON!)
    func getJsep() -> JSON?
    func getMedia() -> MediaServerMediaConstraints!
    func getTrickle() -> Bool!
}
