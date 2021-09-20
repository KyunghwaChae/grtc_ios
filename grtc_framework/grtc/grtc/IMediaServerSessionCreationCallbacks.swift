//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

public protocol IMediaServerSessionCreationCallbacks : IMediaServerCallbacks {
    func onSessionCreationSuccess(_ obj: JSON!)
}
