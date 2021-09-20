//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON
import Starscream

open class MediaServerWSAPI : WebSocketDelegate, IMediaServerMessenger {
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        
    }
    
    private let uri: String!
    private let handler: IMediaServerMessageObserver!
    private let type: MediaServerMessengerType! = MediaServerMessengerType.websocket
    private var client: WebSocket! = nil

    public init(_ uri: String!, _ handler: IMediaServerMessageObserver!) {
        self.uri = uri
        self.handler = handler
    }

    open func getMessengerType() -> MediaServerMessengerType! {
        return type
    }

    open func connect() {
        
        
        
    }


    private func onClose(_ code: Int32, _ reason: String!, _ remote: Bool) {
        handler.onClose()
    }

    private func onError(_ error: String!) {
        handler.onError(error)
    }

    open func disconnect() {
        //client.close()
    }

    open func longPoll(_ sessionId: Int64!) {
    }
    
    
    open func sendMessage(_ message: [String: Any]!) {
        
    }

    open func sendMessage(_ message: [String: Any]!, _ session_id: Int64!) {
        sendMessage(message)
    }

    open func sendMessage(_ message: [String: Any]!, _ session_id: Int64!, _ handle_id: Int64!) {
        sendMessage(message)
    }

    open func receivedMessage(_ msg: JSON!) {
        handler.receivedNewMessage(msg)
    }
}
