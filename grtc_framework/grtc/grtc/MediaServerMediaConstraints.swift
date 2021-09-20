//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation

open class MediaServerMediaConstraints {
    private var sendAudio: Bool = true
    private var video: MediaServerVideo! = MediaServerVideo()
    private var recvVideo: Bool = true
    private var recvAudio: Bool = true
    private var camera: Camera! = Camera.front

    public init() {
    }

    open func getVideo() -> MediaServerVideo! {
        return video
    }

    open func getSendVideo() -> Bool! {
        return video != nil
    }

    open func setVideo(_ video: MediaServerVideo!) {
        self.video = video
    }

    open func getSendAudio() -> Bool {
        return sendAudio
    }

    open func setSendAudio(_ sendAudio: Bool) {
        self.sendAudio = sendAudio
    }

    open func setRecvVideo(_ recvVideo: Bool) {
        self.recvVideo = recvVideo
    }

    open func getRecvVideo() -> Bool {
        return recvVideo
    }

    open func setRecvAudio(_ recvAudio: Bool) {
        self.recvAudio = recvAudio
    }

    open func getRecvAudio() -> Bool {
        return recvAudio
    }

    open func getCamera() -> Camera! {
        return camera
    }

    open func setCamera(_ camera: Camera!) {
        self.camera = camera
    }

    open class MediaServerVideo {
        private var maxHeight: Int32 = 0
        private var minHeight: Int32 = 0
        private var maxWidth: Int32 = 0
        private var minWidth: Int32 = 0
        private var maxFramerate: Int32 = 0
        private var minFramerate: Int32 = 0

        public init() {
            maxFramerate = 30
            minFramerate = 30
            maxHeight = 480
            minHeight = 480
            maxWidth = 640
            minWidth = 640
        }

        open func getMaxHeight() -> Int32 {
            return maxHeight
        }

        open func setMaxHeight(_ maxHeight: Int32) {
            self.maxHeight = maxHeight
        }

        open func getMinHeight() -> Int32 {
            return minHeight
        }

        open func setMinHeight(_ minHeight: Int32) {
            self.minHeight = minHeight
        }

        open func getMaxWidth() -> Int32 {
            return maxWidth
        }

        open func setMaxWidth(_ maxWidth: Int32) {
            self.maxWidth = maxWidth
        }

        open func getMinWidth() -> Int32 {
            return minWidth
        }

        open func setMinWidth(_ minWidth: Int32) {
            self.minWidth = minWidth
        }

        open func getMaxFramerate() -> Int32 {
            return maxFramerate
        }

        open func setMaxFramerate(_ maxFramerate: Int32) {
            self.maxFramerate = maxFramerate
        }

        open func getMinFramerate() -> Int32 {
            return minFramerate
        }

        open func setMinFramerate(_ minFramerate: Int32) {
            self.minFramerate = minFramerate
        }
    }

    public enum Camera {
        case front
        case back
    }
}
