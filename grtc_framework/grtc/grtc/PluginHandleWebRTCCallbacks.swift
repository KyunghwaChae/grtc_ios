//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

open class PluginHandleWebRTCCallbacks : IPluginHandleWebRTCCallbacks {
    private let constraints: MediaServerMediaConstraints!
    private let jsep: JSON?
    private var trickle: Bool = false

    public init(_ constraints: MediaServerMediaConstraints!, _ jsep: JSON!, _ trickle: Bool) {
        self.constraints = constraints
        self.jsep = jsep
        self.trickle = trickle
    }

    open func onSuccess(_ obj: JSON!) {
    }

    open func getJsep() -> JSON? {
        return jsep
    }

    open func getMedia() -> MediaServerMediaConstraints! {
        return constraints
    }

    open func getTrickle() -> Bool! {
        return trickle
    }

    open func onCallbackError(_ error: String!) {
    }
}
