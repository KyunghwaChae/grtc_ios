//
//  IMediaServerMessageObserver.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

public protocol IMediaServerMessageObserver {
    func receivedNewMessage(_ obj: JSON!)
    func onClose()
    func onOpen()
    func onError(_ error: String!)
}
