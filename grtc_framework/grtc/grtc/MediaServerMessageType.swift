//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation

// #error enum can accept only constants
public enum MediaServerMessageType: String {
    case message = "message"
    case trickle = "trickle"
    case detach = "detach"
    case destroy = "destroy"
    case keepalive = "keepalive"
    case create = "create"
    case attach = "attach"
    case event = "event"
    case error = "error"
    case ack = "ack"
    case success = "success"
    case webrtcup = "webrtcup"
    case hangup = "hangup"
    case detached = "detached"
    case media = "media"
}
