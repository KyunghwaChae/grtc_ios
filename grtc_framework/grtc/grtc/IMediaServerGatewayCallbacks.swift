//
//  IMediaServerGatewayCallbacks.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import WebRTC

public protocol IMediaServerGatewayCallbacks : IMediaServerCallbacks {
    func onSuccess()
    func onDestroy()
    func getServerUri() -> String!
    func getIceServers() -> [RTCIceServer]!
    func getIpv6Support() -> Bool!
    func getMaxPollEvents() -> Int32!
    func getWidth() -> Int32!
    func getHeight() -> Int32!
    func getFPS() -> Int32!
    func getCode() -> String!
    func isManager() -> Bool!
}
