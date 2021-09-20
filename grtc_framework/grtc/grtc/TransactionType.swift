//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation

public enum TransactionType {
    case create
    case attach
    case message
    case trickle
    case plugin_handle_message
    case plugin_handle_webrtc_message
}
