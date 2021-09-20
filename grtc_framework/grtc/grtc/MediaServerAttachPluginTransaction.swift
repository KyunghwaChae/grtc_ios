//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

open class MediaServerAttachPluginTransaction : ITransactionCallbacks {
    private let callbacks: IMediaServerAttachPluginCallbacks!
    private let plugin: MediaServerSupportedPluginPackages!
    private let pluginCallbacks: IMediaServerPluginCallbacks!

    public init(_ callbacks: IMediaServerAttachPluginCallbacks!, _ plugin: MediaServerSupportedPluginPackages!, _ pluginCallbacks: IMediaServerPluginCallbacks!) {
        self.callbacks = callbacks
        self.plugin = plugin
        self.pluginCallbacks = pluginCallbacks
    }

    open func getTransactionType() -> TransactionType! {
        return TransactionType.attach
    }

    open func reportSuccess(_ obj: JSON!) {
        let type = MediaServerMessageType(rawValue: obj["janus"].rawString()!)
        if type != MediaServerMessageType.success {
            callbacks.onCallbackError(obj["error"]["reason"].rawString())
        } else {
            callbacks.attachPluginSuccess(obj, plugin, pluginCallbacks)
        }
    }
}
