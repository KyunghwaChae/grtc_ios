//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON

public protocol IMediaServerAttachPluginCallbacks : IMediaServerCallbacks {
    func attachPluginSuccess(_ obj: JSON!, _ plugin: MediaServerSupportedPluginPackages!, _ callbacks: IMediaServerPluginCallbacks!)
}
