//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

open class PluginHandleSendMessageCallbacks : IPluginHandleSendMessageCallbacks {
    private let message: JSON!

    public init(_ message: JSON!) {
        self.message = message
    }

    open func onSuccessSynchronous(_ obj: JSON!) {
    }

    open func onSuccesAsynchronous() {
    }

    open func getMessage() -> JSON! {
        return message
    }

    open func onCallbackError(_ error: String!) {
    }
}
