//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation

// #error enum can accept only constants
public enum MediaServerSupportedPluginPackages: String {
    case JANUS_AUDIO_BRIDGE = "janus.plugin.audiobridge"
    case JANUS_ECHO_TEST = "janus.plugin.echotest"
    case JANUS_RECORD_PLAY = "janus.plugin.recordplay"
    case JANUS_STREAMING = "janus.plugin.streaming"
    case JANUS_SIP = "janus.plugin.sip"
    case JANUS_VIDEO_CALL = "janus.plugin.videocall"
    case JANUS_VIDEO_ROOM = "janus.plugin.videoroom"
    case JANUS_VOICE_MAIL = "janus.plugin.voicemail"
    case JANUS_NONE = "none"
}
