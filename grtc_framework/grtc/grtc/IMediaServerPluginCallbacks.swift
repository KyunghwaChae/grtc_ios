//
//  IMediaServerPluginCallbacks.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import WebRTC
import SwiftyJSON

public protocol IMediaServerPluginCallbacks : IMediaServerCallbacks {
    func success(_ handle: MediaServerPluginHandle!)
    func onMessage(_ msg: JSON!, _ jsep: JSON!)
    func onLocalVideoTrack(_ track: RTCVideoTrack!)
    func onRemoteStream(_ stream: RTCMediaStream!)
    func onDataOpen(_ data: AnyObject!)
    func onData(_ data: AnyObject!)
    func onCleanup()
    func onDetached()
    func getFeedId() -> Int64!
    func getPlugin() -> MediaServerSupportedPluginPackages!
}
