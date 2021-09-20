//
//  IMediaServerMessenger.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

public protocol IMediaServerMessenger {
    func connect()
    func disconnect()
    func longPoll(_ sessionId: Int64!)
    func sendMessage(_ message: [String: Any]!)
    func sendMessage(_ message: [String: Any]!, _ sessionid: Int64!)
    func sendMessage(_ message: [String: Any]!, _ sessionid: Int64!, _ handleid: Int64!)
    func receivedMessage(_ message: JSON!)
    func getMessengerType() -> MediaServerMessengerType!
}
