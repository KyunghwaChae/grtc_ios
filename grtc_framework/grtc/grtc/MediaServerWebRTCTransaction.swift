//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

open class MediaServerWebRTCTransaction : ITransactionCallbacks {
    private let callbacks: IPluginHandleWebRTCCallbacks!
    private let plugin: MediaServerSupportedPluginPackages!

    public init(_ plugin: MediaServerSupportedPluginPackages!, _ callbacks: IPluginHandleWebRTCCallbacks!) {
        self.callbacks = callbacks
        self.plugin = plugin
    }

    open func getTransactionType() -> TransactionType! {
        return TransactionType.plugin_handle_webrtc_message
    }

    open func reportSuccess(_ obj: JSON!) {
        let type: MediaServerMessageType! = MediaServerMessageType(rawValue: obj["janus"].string!)
        switch type {
        case .success, .ack: break
        default:
            callbacks.onCallbackError(obj["error"]["reason"].rawString())
        }
    }
}
