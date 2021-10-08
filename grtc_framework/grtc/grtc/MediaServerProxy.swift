//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import WebRTC
import SwiftyJSON

public protocol MediaServerProxyObserver {
    func onCreatedRoom(_ sessionId: Int64!, _ publishId: Int64!)
    func onJoinedRoom(_ sessionId: Int64!, _ publishId: Int64!)
    func onLeaveRoom(_ publishId: Int64!, _ code: String!)
    func onPublish(_ publishId: Int64!, _ code: String!)
    func onUnpublish(_ publishId: Int64!, _ code: String!)
    func onVideo(_ code: String!, _ enable: Bool!)
    func onExistUser(_ code:String!)
    func onExitUser()
}

public class MediaServerProxy {
    private let TAG: String! = "MediaServerProxy"
    private var _handle: MediaServerPluginHandle! = nil
    private var _local_renderer: RTCVideoRenderer?
    private var _remote_renderers: Dictionary<Int64, RTCVideoRenderer> = Dictionary<Int64, RTCVideoRenderer>()
    private var _remote_codes: Dictionary<Int64, String> = Dictionary<Int64, String>()
    private var _remote_codes_renderers: Dictionary<String, RTCVideoRenderer> = Dictionary<String, RTCVideoRenderer>()
    private var _media_server: MediaServer!
    private var _my_id: Int64!
    private var _media_server_uri: String!
    private var _code: String!
    private var _room_id: Int32 = 0
    private var _width: Int32 = 0
    private var _height: Int32 = 0
    private var _fps: Int32 = 0
    private var _vbitrate_mbps: Int32 = 0
    private var _bRecord: Bool = false
    private var _bForceJoin: Bool = false
    internal var _observer: MediaServerProxyObserver!
    internal var _remote_ms: Dictionary<Int64, RTCMediaStream> = Dictionary<Int64, RTCMediaStream>()

    public init(_ localRenderer: RTCVideoRenderer!, _ remoteRenderers: [RTCVideoRenderer], _ remoteCodes: [String], _ mediaServerUri: String!, _ code: String!, _ roomId: Int32, _ width: Int32, _ height: Int32, _ fps: Int32, _ vbitrateMbps: Int32, _ bRecord: Bool, _ bForceJoin: Bool, _ observer: MediaServerProxyObserver!) {
        
        _local_renderer = localRenderer
        for (index, value) in remoteCodes.enumerated() {
            _remote_codes_renderers[value] = remoteRenderers[index]
        }
        _media_server_uri = mediaServerUri
        _code = code
        _room_id = roomId
        _width = width
        _height = height
        _fps = fps
        _vbitrate_mbps = vbitrateMbps
        _bRecord = bRecord
        _bForceJoin = bForceJoin
        _observer = observer
        _media_server = MediaServer(MediaServerGlobalCallbacks(self))
    }

    public func enableAudio(_ enable: Bool) {
        if let handle = _handle {
            handle.enableAudio(enable)
        }
    }
    
    public func enableVideo(_ enable: Bool) {
        if let handle = _handle {
            handle.enableVideo(enable)
        }
    }

    public func Start() {
        _media_server.Connect()
    }
    
    public func Stop() {
        _media_server.Destroy()
    }

    internal class SubscriberAttachCallbacks : IMediaServerPluginCallbacks {
        
        private var _renderer: RTCVideoRenderer! = nil
        private var _feedid: Int64! = -1
        private var _handle: MediaServerPluginHandle! = nil
        private var _parent: MediaServerProxy! = nil
        
        class CreateAnswerCallbacks : IPluginHandleWebRTCCallbacks {
            
            private var _renderer: RTCVideoRenderer! = nil
            private var _parent: SubscriberAttachCallbacks! = nil
            private var _jsep: JSON! = nil
            
            init(_ parent: SubscriberAttachCallbacks, _ jsep: JSON) {
                _parent = parent
                _jsep = jsep
            }
            
            func onSuccess(_ obj: JSON!) {
                var mymsg = JSON()
                var body = JSON()
                body["request"].string = "start"
                body["room"].int32 = self._parent._parent._room_id
                mymsg["message"].object = body
                mymsg["jsep"].object = obj.object
                self._parent._handle.sendMessage(PluginHandleSendMessageCallbacks(mymsg))
            }
            
            func getJsep() -> JSON? {
                return _jsep
            }
            
            func getMedia() -> MediaServerMediaConstraints! {
                let cons: MediaServerMediaConstraints! = MediaServerMediaConstraints()
                cons.setVideo(nil)
                cons.setRecvAudio(true)
                cons.setRecvVideo(true)
                cons.setSendAudio(false)
                return cons
            }
            
            func getTrickle() -> Bool! {
                return true
            }
            
            func onCallbackError(_ error: String!) {

            }
        }
        
        init(_ feedid: Int64!, _ renderer: RTCVideoRenderer!, _ parent: MediaServerProxy!) {
            _feedid = feedid
            _renderer = renderer
            _parent = parent
        }

        public func getFeedId() -> Int64! {
            return _feedid
        }
        
        private func leave() {
            if _parent._handle != nil {
                var obj: JSON! = JSON()
                var msg: JSON! = JSON()
                
                obj["request"].string = "leave"
                msg["message"].object = obj.object
                
                _parent._handle.sendMessage(PluginHandleSendMessageCallbacks(msg))
            }
        }

        public func success(_ handle: MediaServerPluginHandle!) {
            _handle = handle
            var body = JSON()
            var msg = JSON()
            body["request"].string = "join"
            body["room"].int32 = self._parent._room_id
            body["ptype"].string = "subscriber"
            body["feed"].int64 = _feedid
            msg["message"].object = body
            handle.sendMessage(PluginHandleSendMessageCallbacks(msg))
        }
        
        public func onMessage(_ msg: JSON!, _ jsep: JSON!) {
            
            let event = msg["videoroom"]
            if event == "attached" && jsep != nil {
                let callback = CreateAnswerCallbacks(self, jsep)
                _handle.createAnswer(callback)
            } else {
                if msg["leaving"].exists() {
                    
                } else if msg["unpublished"].exists() {
                       
                } else {
                    
                }
            }
        }

        public func onLocalVideoTrack(_ track: RTCVideoTrack!) {
        }

        public func onRemoteStream(_ stream: RTCMediaStream!) {
            stream.videoTracks[0].add(_renderer)
            _parent._remote_ms[_feedid] = stream
        }

        public func onDataOpen(_ data: Any!) {
        }

        public func onData(_ data: Any!) {
            let json = data as! JSON
            if json["camera"].exists() {
                let camera = json["camera"]
                if camera["code"].exists() {
                    let code = camera["code"].string
                    let enable = camera["enable"].bool
                    if let observer = _parent._observer {
                        
                        let handler = DispatchQueue(label: "kr.co.grib.onvideo", qos: .userInteractive)
                        handler.async {
                            observer.onVideo(code, enable)
                        }
                    }
                }
            }
        }

        public func onCleanup() {
            leave()
        }

        public func onDetached() {
            _parent._remote_ms.removeValue(forKey: _feedid)
        }

        public func getPlugin() -> MediaServerSupportedPluginPackages! {
            return MediaServerSupportedPluginPackages.JANUS_VIDEO_ROOM
        }

        public func onCallbackError(_ error: String!) {
        }
    }

    internal class MediaServerPublisherPluginCallbacks : IMediaServerPluginCallbacks {
        
        private let _parent: MediaServerProxy!
        private var _bRoomCreator: Bool! = false
        init(_ parent: MediaServerProxy!) {
            _parent = parent
        }
        
        class CreateOfferCallbacks : IPluginHandleWebRTCCallbacks {
            
            private let _parent: MediaServerPublisherPluginCallbacks!
            
            init(_ parent: MediaServerPublisherPluginCallbacks!) {
                _parent = parent
            }
            
            func onSuccess(_ obj: JSON!) {
                var msg: JSON! = JSON()
                var body: JSON! = JSON()
                body["request"].string = "publish"
                body["audio"].bool = true
                body["video"].bool = true
                body["data"].bool = true
                //body["audiocodec"].string = "opus"
                //body["videocodec"].string = "vp8"
                body["bitrate"].int32 = _parent._parent._vbitrate_mbps * 1024 * 1024
                /*
                if self._parent._parent._bRecord {
                    body["record"].bool = true
                } else {
                    body["record"].bool = false
                }
                */
                msg["message"].object = body.object
                msg["jsep"].object = obj.object
                _parent._parent._handle.sendMessage(PluginHandleSendMessageCallbacks(msg))
            }

            func getJsep() -> JSON? {
                return nil
            }

            func getMedia() -> MediaServerMediaConstraints! {
                let cons: MediaServerMediaConstraints! = MediaServerMediaConstraints()
                cons.setRecvAudio(false)
                cons.setRecvVideo(false)
                cons.setSendAudio(true)
                return cons
            }

            func getTrickle() -> Bool! {
                return true
            }

            func onCallbackError(_ error: String!) {
            }
        }
        
        private func publishOwnFeed() {
            if _parent._handle != nil {
                let callback = CreateOfferCallbacks(self)
                _parent._handle.createOffer(callback)
            }
        }

        private func createRoom() {
            if _parent._handle != nil {
                var obj: JSON! = JSON()
                var msg: JSON!  = JSON()

                obj["request"].string = "create"
                obj["room"].int32 = _parent._room_id
                obj["publishers"].int = 9
                //obj["audiocodec"].string = "opus"
                //obj["videocodec"].string = "vp8"
                //obj["h264_profile"].string = "42e01f"
                obj["is_private"].bool = false
                obj["rec_dir"].string = "/home/ubuntu/recording/\(self._parent._room_id)"
                msg["message"].object = obj.object
                
                _parent._handle.sendMessage(PluginHandleSendMessageCallbacks(msg))
            }
        }

        private func registerUsername() {
            if _parent._handle != nil {
                var obj: JSON! = JSON()
                var msg: JSON! = JSON()

                obj["request"].string = "join"
                obj["room"].int32 = _parent._room_id
                obj["ptype"].string = "publisher"
                obj["display"].string = _parent._code
                msg["message"].object = obj.object
                
                _parent._handle.sendMessage(PluginHandleSendMessageCallbacks(msg))
            }
        }

        private func listParticipants() {
            if _parent._handle != nil {
                var obj: JSON! = JSON()
                var msg: JSON! = JSON()
                
                obj["request"].string = "listparticipants"
                obj["room"].int32 = _parent._room_id
                msg["message"].object = obj.object
                
                _parent._handle.sendMessage(PluginHandleSendMessageCallbacks(msg))
            }
        }
        
        private func leave() {
            if _parent._handle != nil {
                var obj: JSON! = JSON()
                var msg: JSON! = JSON()
                
                obj["request"].string = "leave"
                msg["message"].object = obj.object
                
                _parent._handle.sendMessage(PluginHandleSendMessageCallbacks(msg))
            }
        }
        
        private func newRemoteFeed(_ id: Int64!, _ code: String!, _ bVideo: Bool!) {
            // todo attach the plugin as a listener
            if let myrenderer = _parent._remote_codes_renderers[code] {
                
                if _parent._remote_renderers[id] == nil {
                    _parent._remote_renderers[id] = myrenderer
                }
                if _parent._remote_codes[id] == nil {
                    _parent._remote_codes[id] = code
                }
                if let observer = _parent._observer {
                    let handler = DispatchQueue(label: "kr.co.grib.observer", qos: .userInteractive)
                    handler.async {
                        
                        observer.onPublish(id, code)
                        observer.onVideo(code, bVideo)
                    }
                }
                _parent._media_server.Attach(SubscriberAttachCallbacks(id, myrenderer, _parent))
            } else {
                if _parent._remote_codes[id] == nil {
                    _parent._remote_codes[id] = code
                }
                if let observer = _parent._observer {
                    let handler = DispatchQueue(label: "kr.co.grib.observer", qos: .userInteractive)
                    handler.async {
                        observer.onPublish(id, code)
                    }
                }
            }
        }

        public func getFeedId() -> Int64! {
            return -1
        }

        public func success(_ pluginHandle: MediaServerPluginHandle!) {
            _parent._handle = pluginHandle
            createRoom()
        }

        public func onMessage(_ msg: JSON!, _ jsepLocal: JSON!) {

            let event: String! = msg["videoroom"].rawString()
            if event == "participants" {
                var exist = false
                
                if msg["participants"].exists() {
                    if let participants: [JSON] = msg["participants"].array {
                        for participant in participants {
                            if let code = participant["display"].string {
                                if code == _parent._code {
                                    exist = true
                                    break
                                }
                            }
                        }
                    }
                }
                
                if(exist) {
                    if let observer = _parent._observer {
                        let handler = DispatchQueue(label: "kr.co.grib.observer", qos: .userInteractive)
                        handler.async {
                            observer.onExistUser(self._parent._code)
                        }
                    }
                } else {
                    registerUsername()
                }
            } else if event == "created" {
                self._bRoomCreator = true
                if self._parent._bForceJoin {
                    registerUsername()
                } else {
                    listParticipants()
                }
            } else if event == "joined" {
                _parent._my_id = msg["id"].int64
                publishOwnFeed()
                if msg["publishers"].exists() {
                    
                    if let pubs: [JSON] = msg["publishers"].array {
                        for pub in pubs {
                            let tehId: Int64! = pub["id"].int64
                            let code: String! = pub["display"].string
                            newRemoteFeed(tehId, code, true)
                        }
                    }
                }
                if self._bRoomCreator {
                    if let observer = _parent._observer {
                        let handler = DispatchQueue(label: "kr.co.grib.observer", qos: .userInteractive)
                        handler.async {
                            observer.onCreatedRoom(self._parent._media_server.getSessionId(), self._parent._my_id)
                        }
                    }
                } else {
                    if let observer = _parent._observer {
                        let handler = DispatchQueue(label: "kr.co.grib.observer", qos: .userInteractive)
                        handler.async {
                            observer.onJoinedRoom(self._parent._media_server.getSessionId(), self._parent._my_id)
                        }
                    }
                }
            } else {
                if event == "destroyed" {
                    
                } else {
                    
                    if event == "event"  {
                        if msg["publishers"].exists() {
                            let pubs: [JSON] = msg["publishers"].arrayValue
                            for i in 0 ... pubs.count - 1 {
                                let pub: JSON! = pubs[i]
                                let theId = pub["id"].int64
                                let code = pub["display"].string
                                if code==self._parent._code {
                                    if let observer = _parent._observer {
                                        let handler = DispatchQueue(label: "kr.co.grib.observer", qos: .userInteractive)
                                        handler.async {
                                            observer.onExitUser()
                                        }
                                    }
                                } else {
                                    newRemoteFeed(theId, code, true)
                                }
                            }
                        } else {
                            if msg["leaving"].exists() {
                                if let id = msg["leaving"].int64 {
                                    if _parent._remote_renderers.keys.contains(id) {
                                        _parent._remote_renderers.removeValue(forKey: id)
                                    }
                                    
                                    if let observer = _parent._observer {
                                        if self._parent._remote_codes.keys.contains(id) {
                                            let code = self._parent._remote_codes[id]
                                            let handler = DispatchQueue(label: "kr.co.grib.observer", qos: .userInteractive)
                                            handler.async {
                                                observer.onLeaveRoom(id, code)
                                                
                                            }
                                        }
                                    }
                                    _parent._media_server.Detach(id)
                                }
                            } else {
                                if msg["unpublished"].exists() {
                                    if let id = msg["unpublished"].int64 {
                                        if let observer = _parent._observer {
                                            if self._parent._remote_codes.keys.contains(id) {
                                                let code = self._parent._remote_codes[id]
                                                let handler = DispatchQueue(label: "kr.co.grib.observer", qos: .userInteractive)
                                                handler.async {
                                                    observer.onUnpublish(id, code)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    if msg["error_code"].exists() {
                                        if msg["error_code"].int == 427 { // room alreay exists
                                            self._bRoomCreator = false
                                            if self._parent._bForceJoin {
                                                registerUsername()
                                            } else {
                                                listParticipants()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if jsepLocal != nil {
                _parent._handle.handleRemoteJsep(PluginHandleWebRTCCallbacks(nil, jsepLocal, false))
            }
        }

        public func onLocalVideoTrack(_ track: RTCVideoTrack!) {
            if let renderer = _parent._local_renderer {
                track.add(renderer)
            }
        }

        public func onRemoteStream(_ stream: RTCMediaStream!) {
            NSLog("[MediaServerProxy] onRemoteStream\n");
        }

        public func onDataOpen(_ data: Any!) {
        }

        public func onData(_ data: Any!) {
        }

        public func onCleanup() {
            leave()
        }

        public func getPlugin() -> MediaServerSupportedPluginPackages! {
            return MediaServerSupportedPluginPackages.JANUS_VIDEO_ROOM
        }

        public func onCallbackError(_ error: String!) {
        }

        public func onDetached() {
        }
    }

    open class MediaServerGlobalCallbacks : IMediaServerGatewayCallbacks {

        private var _parent: MediaServerProxy!
        
        init(_ parent: MediaServerProxy!) {
            _parent = parent
        }
        
        open func onSuccess() {
            _parent._media_server.Attach(MediaServerPublisherPluginCallbacks(_parent))
        }

        open func onDestroy() {
        }

        open func getServerUri() -> String! {
            return _parent._media_server_uri
        }

        open func getIceServers() -> [RTCIceServer]! {
            var iceServers: [RTCIceServer]! = [RTCIceServer].init()
            iceServers.append(RTCIceServer.init(urlStrings: ["stun:stun.markx.co.kr:3478"]))
            iceServers.append(RTCIceServer.init(urlStrings: ["turn:turn.markx.co.kr:3478"], username: "markx", credential: "markt2021"))
            return iceServers
        }

        open func getIpv6Support() -> Bool! {
            return false
        }

        open func getMaxPollEvents() -> Int32! {
            return 0
        }

        open func onCallbackError(_ error: String!) {
        }

        open func getWidth() -> Int32! {
            return _parent._width
        }

        open func getHeight() -> Int32! {
            return _parent._height
        }

        open func getFPS() -> Int32! {
            return _parent._fps
        }
        
        open func getCode() -> String! {
            return _parent._code;
        }
    }
}
