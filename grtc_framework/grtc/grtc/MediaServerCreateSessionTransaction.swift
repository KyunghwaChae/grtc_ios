//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

open class MediaServerCreateSessionTransaction : ITransactionCallbacks {
    private let callbacks: IMediaServerSessionCreationCallbacks!

    public init(_ callbacks: IMediaServerSessionCreationCallbacks!) {
        self.callbacks = callbacks
    }

    open func getTransactionType() -> TransactionType! {
        return TransactionType.create
    }

    open func reportSuccess(_ obj: JSON!) {
        let type = MediaServerMessageType(rawValue: obj["janus"].rawString()!)
        if type != MediaServerMessageType.success {
            callbacks.onCallbackError(obj["error"]["reason"].rawString())
        } else {
            callbacks.onSessionCreationSuccess(obj)
        }
    }
}
