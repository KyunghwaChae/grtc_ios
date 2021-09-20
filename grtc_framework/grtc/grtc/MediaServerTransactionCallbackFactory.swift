//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation

public class MediaServerTransactionCallbackFactory {
    public static func createNewTransactionCallback(_ server: MediaServer!, _ type: TransactionType!) -> ITransactionCallbacks! {
        switch type {
        case .create:
            return MediaServerCreateSessionTransaction(server)
        default:
            return nil
        }
    }

    public static func createNewTransactionCallback(_ server: MediaServer!, _ type: TransactionType!, _ plugin: MediaServerSupportedPluginPackages!, _ callbacks: IPluginHandleWebRTCCallbacks!) -> ITransactionCallbacks! {
        switch type {
        case .plugin_handle_webrtc_message:
            return MediaServerWebRTCTransaction(plugin, callbacks)
        default:
            return nil
        }
    }

    public static func createNewTransactionCallback(_ server: MediaServer!, _ type: TransactionType!, _ plugin: MediaServerSupportedPluginPackages!, _ callbacks: IPluginHandleSendMessageCallbacks!) -> ITransactionCallbacks! {
        switch type {
        case .plugin_handle_message:
            return MediaServerSendPluginMessageTransaction(plugin, callbacks)
        default:
            return nil
        }
    }

    public static func createNewTransactionCallback(_ server: MediaServer!, _ type: TransactionType!, _ plugin: MediaServerSupportedPluginPackages!, _ callbacks: IMediaServerPluginCallbacks!) -> ITransactionCallbacks! {
        switch type {
        case .create:
            return MediaServerCreateSessionTransaction(server)
        case .attach:
            return MediaServerAttachPluginTransaction(server, plugin, callbacks)
        default:
            return nil
        }
    }
}
