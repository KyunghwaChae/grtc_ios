//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

public protocol IPluginHandleSendMessageCallbacks : IMediaServerCallbacks {
    func onSuccessSynchronous(_ obj: JSON!)
    func onSuccesAsynchronous()
    func getMessage() -> JSON!
}
