//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

open class MediaServerSendPluginMessageTransaction : ITransactionCallbacks {
    private let callbacks: IPluginHandleSendMessageCallbacks!

    public init(_ plugin: MediaServerSupportedPluginPackages!, _ callbacks: IPluginHandleSendMessageCallbacks!) {
        self.callbacks = callbacks
    }

    open func getTransactionType() -> TransactionType! {
        return TransactionType.plugin_handle_message
    }

    open func reportSuccess(_ obj: JSON!) {
        let type: MediaServerMessageType! = MediaServerMessageType(rawValue: obj["janus"].rawString()!)
        switch type {
        case .success:
            let plugindata: JSON! = obj["plugindata"]
            let plugin: MediaServerSupportedPluginPackages! = MediaServerSupportedPluginPackages(rawValue: plugindata["plugin"].rawString()!)
            let data: JSON! = plugindata["data"]
            if plugin == MediaServerSupportedPluginPackages.JANUS_NONE {
                callbacks.onCallbackError("unexpected message: \n\t" + obj.rawString()!)
            } else {
                callbacks.onSuccessSynchronous(data)
            }
        case .ack:
            callbacks.onSuccesAsynchronous()
        default:
            callbacks.onCallbackError(obj["error"]["reason"].rawString())
        }
    }
}
