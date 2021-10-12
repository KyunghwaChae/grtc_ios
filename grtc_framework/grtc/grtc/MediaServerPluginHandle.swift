//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation
import SwiftyJSON
import WebRTC

open class MediaServerPluginHandle: NSObject {
    private let TAG: String! = "MediaServerPluginHandle"

    private var _started: Bool = false
    private var _video_track: RTCVideoTrack! = nil
    private var _audio_track: RTCAudioTrack! = nil
    private var _remote_stream: RTCMediaStream! = nil
    private var _my_sdp: RTCSessionDescription! = nil
    private var _pc: RTCPeerConnection! = nil
    
    private var _max_bitrate_mbps: Int32 = 2
    private var _data_channel: RTCDataChannel! = nil
    private var _trickle: Bool = true
    private var _ice_done: Bool = false
    private var _sdp_sent: Bool = false
    private var _sdp_cbks: IPluginHandleWebRTCCallbacks! = nil
    
    private var _code: String! = nil
    private var _width: Int32 = 0
    private var _height: Int32 = 0
    private var _fps: Int32 = 0
    private var _session_factory: RTCPeerConnectionFactory! = nil
    private var _server: MediaServer! = nil
    public var _plugin: MediaServerSupportedPluginPackages! = nil
    public var _id: Int64! = -1
    private var _callbacks: IMediaServerPluginCallbacks! = nil
    private var _capturer: RTCVideoCapturer! = nil
    internal var _pc_constraints: RTCMediaConstraints! = nil
    internal var _sdp_constraints: RTCMediaConstraints! = nil
    private let VIDEO_TRACK_ID: String! = "ARDAMSv0"
    private let AUDIO_TRACK_ID: String! = "ARDAMSa0"
    private let LOCAL_MEDIA_ID: String! = "ARDAMS"
    

    public init(_ server: MediaServer!, _ code: String!, _ plugin: MediaServerSupportedPluginPackages!, _ handle_id: Int64!, _ callbacks: IMediaServerPluginCallbacks!, _ width: Int32, _ height: Int32, _ fps: Int32) {
        _server = server
        _code = code
        _plugin = plugin
        _id = handle_id
        _callbacks = callbacks
        _width = width
        _height = height
        _fps = fps

        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        _session_factory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }

    open func onMessage(_ msg: String!) {
        do {
            let encodedString = msg.data(using: String.Encoding.utf8, allowLossyConversion: false)
            let obj = try JSON(data: encodedString!)
            _callbacks.onMessage(obj, nil)
        } catch {}
    }

    open func onMessage(_ msg: JSON!, _ jsep: JSON!) {
        _callbacks.onMessage(msg, jsep)
    }
    
    private func onLocalVideoTrack(_ track: RTCVideoTrack!) {
        _callbacks.onLocalVideoTrack(track)
    }

    private func onRemoteStream(_ stream: RTCMediaStream!) {
        _callbacks.onRemoteStream(stream)
    }

    open func onDataOpen(_ data: Any!) {
        _callbacks.onDataOpen(data)
    }

    open func onData(_ data: Any!) {
        _callbacks.onData(data)
    }

    open func onCleanup() {
        _callbacks.onCleanup()
    }

    open func onDetached() {
        _callbacks.onDetached()
    }

    open func sendMessage(_ obj: IPluginHandleSendMessageCallbacks!) {
        _server.sendMessage(TransactionType.plugin_handle_message, _id, obj, _plugin)
    }

    open func enableAudio(_ enable: Bool!) {
        _audio_track.isEnabled = enable
    }
    
    open func enableVideo(_ enable: Bool!) {
        _video_track.isEnabled = enable
        if _data_channel.readyState == RTCDataChannelState.open {
            do {
                var msg = JSON()
                var body = JSON()
                body["code"].string = self._code
                body["enable"].bool = enable
                msg["camera"].object = body.object
                let buffer = try RTCDataBuffer(data: msg.rawData(), isBinary: false)
                _data_channel?.sendData(buffer)
            } catch {}
        }
    }
    
    private func streamsDone(_ callbacks: IPluginHandleWebRTCCallbacks!) {
        _pc_constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
        let rtcConfig = RTCConfiguration()
        rtcConfig.iceServers = _server._ice_servers
        rtcConfig.iceTransportPolicy = RTCIceTransportPolicy.all
        rtcConfig.tcpCandidatePolicy = RTCTcpCandidatePolicy.disabled
        rtcConfig.bundlePolicy = RTCBundlePolicy.maxBundle
        rtcConfig.rtcpMuxPolicy = RTCRtcpMuxPolicy.require
        rtcConfig.continualGatheringPolicy = RTCContinualGatheringPolicy.gatherContinually
        rtcConfig.keyType = RTCEncryptionKeyType.ECDSA
        
        _pc = _session_factory.peerConnection(with: rtcConfig, constraints: _pc_constraints, delegate: self)
        if let videoTrack = _video_track {
            _pc.add(videoTrack, streamIds: [VIDEO_TRACK_ID])
        }
        if let audioTrack = _audio_track {
            _pc.add(audioTrack, streamIds: [AUDIO_TRACK_ID])
        }
        
        if let code = _code {
            if code.count > 0 {
                let config = RTCDataChannelConfiguration()
                _data_channel = _pc.dataChannel(forLabel: code, configuration: config)
                _data_channel.delegate = self
            }
        }
        
        if callbacks.getJsep() == nil {
            createSdpInternal(callbacks, true)
        } else {
            let obj: JSON! = callbacks.getJsep()
            let sdp: String! = obj["sdp"].rawString()
            var type: RTCSdpType! = RTCSdpType.offer
            if obj["type"].rawString()! == "offer" {
                type = RTCSdpType.offer
            } else {
                type = RTCSdpType.answer
            }
            let sessionDescription: RTCSessionDescription! = RTCSessionDescription(type: type, sdp: sdp)
            _pc.setRemoteDescription(sessionDescription) { (error) in
                if let err = error {
                    print("Failed to set remote offer SDP")
                    //print("\(error)")
                    callbacks.onCallbackError("Failed to set remote offer SDP:\(err)")
                    return;
                }
                
                //print("Succeed to set remote offer SDP")
                if self._my_sdp == nil {
                    self.createSdpInternal(callbacks, false)
                }
            }
        }
    }

    open func createOffer(_ webrtcCallbacks: IPluginHandleWebRTCCallbacks!) {
        let offer = DispatchQueue(label: "kr.co.grib.offer", qos: .userInteractive)
        offer.async {
            self.prepareWebRTC(webrtcCallbacks)
        }
    }

    open func createAnswer(_ webrtcCallbacks: IPluginHandleWebRTCCallbacks!) {
        let answer = DispatchQueue(label: "kr.co.grib.answer", qos: .userInteractive)
        answer.async {
            self.prepareWebRTC(webrtcCallbacks)
        }
    }

    private func prepareWebRTC(_ callbacks: IPluginHandleWebRTCCallbacks!) {
        if _pc != nil {
            if callbacks.getJsep() == nil {
                createSdpInternal(callbacks, true)
            } else {
                let jsep: JSON! = callbacks.getJsep()
                let sdpString: String! = jsep["sdp"].rawString()
                var type = RTCSdpType.offer
                if jsep["type"]=="offer" {
                    type = RTCSdpType.offer
                } else {
                    type = RTCSdpType.answer
                }
                let sdp: RTCSessionDescription! = RTCSessionDescription(type: type, sdp: sdpString)
                _pc.setRemoteDescription(sdp) { (error) in
                    if let err = error {
                        print("Failed to set remote offer SDP")
                        //print("\(error)")
                        callbacks.onCallbackError("Failed to set remote offer SDP:\(err)")
                        return;
                    }
                    
                    //print("Succeed to set remote offer SDP")
                    if self._my_sdp == nil {
                        self.createSdpInternal(callbacks, false)
                    }
                }

            }
        } else {
            _trickle = (callbacks.getTrickle() != nil ? callbacks.getTrickle() : false)
            if callbacks.getMedia().getSendAudio() {
                let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
                let audioSource = _session_factory.audioSource(with: audioConstrains)
               _audio_track = _session_factory.audioTrack(with: audioSource, trackId: AUDIO_TRACK_ID)
               _audio_track.isEnabled = true
            }
            if callbacks.getMedia().getSendVideo() {
                let videoSource = _session_factory.videoSource()
                #if TARGET_OS_SIMULATOR
                _capturer = RTCFileVideoCapturer(delegate: videoSource)
                #else
                _capturer = RTCCameraVideoCapturer(delegate: videoSource)
                #endif

                if let capturer = _capturer as? RTCCameraVideoCapturer {
                    
                    capturer.stopCapture()
                    
                    var targetDevice: AVCaptureDevice?
                    var targetFormat: AVCaptureDevice.Format?
                    let devices = RTCCameraVideoCapturer.captureDevices()
                    devices.forEach { (device) in
                        if device.position == .front {
                            targetDevice = device
                        }
                    }
                    
                    let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice!)
                    formats.forEach { (format) in
                        for _ in format.videoSupportedFrameRateRanges {
                            let description = format.formatDescription as CMFormatDescription
                            let dimension = CMVideoFormatDescriptionGetDimensions(description)
                            if dimension.width == self._width && dimension.height == self._height {
                                targetFormat = format
                            } else if dimension.width == self._width {
                                targetFormat = format
                            }
                        }
                    }
                    capturer.startCapture(with: targetDevice!, format: targetFormat!, fps: Int(self._fps), completionHandler: nil)
                }
                _video_track = _session_factory.videoTrack(with: videoSource, trackId: VIDEO_TRACK_ID)
                _video_track.isEnabled = true
                onLocalVideoTrack(_video_track)
            }
            streamsDone(callbacks)
        }
    }
    
    private func createSdpInternal(_ callbacks: IPluginHandleWebRTCCallbacks!, _ isOffer: Bool!) {
        
        if callbacks.getMedia().getRecvAudio() && callbacks.getMedia().getRecvVideo() {

            let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
            self._sdp_constraints = RTCMediaConstraints(mandatoryConstraints: mediaConstrains, optionalConstraints: nil)

        } else if callbacks.getMedia().getRecvVideo() {

            let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
            self._sdp_constraints = RTCMediaConstraints(mandatoryConstraints: mediaConstrains, optionalConstraints: nil)

        } else if callbacks.getMedia().getRecvAudio() {

            let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue]
            self._sdp_constraints = RTCMediaConstraints(mandatoryConstraints: mediaConstrains, optionalConstraints: nil)

        } else {
            
            self._sdp_constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        
        }
        
        if isOffer {
            _pc.offer(for: _sdp_constraints) { (sdp, error) in
                if let err = error {
                    print("failed in creating offer")
                    //print(err)
                    callbacks.onCallbackError("failed in creating offer : \(err)")
                    return//
                }
                
                //print("succeed in creating offer")
                self.onLocalSdp(sdp, callbacks)
            }
        } else {
            _pc.answer(for: _sdp_constraints) { (sdp, error) in
                if let err = error {
                    print("failed in creating answer")
                    //print(err)
                    callbacks.onCallbackError("failed in creating answer : \(err)")
                    return
                }
                
                //print("succeed in creating answer")
                self.onLocalSdp(sdp, callbacks)
            }
        }
        
    }

    open func handleRemoteJsep(_ callbacks: IPluginHandleWebRTCCallbacks!) {
        let handleRJ = DispatchQueue(label: "kr.co.grib.handleRJ", qos: .userInteractive)
        handleRJ.async {
            let jsep: JSON! = callbacks.getJsep()
            if jsep != nil {
                if self._pc == nil {
                    self._callbacks.onCallbackError("No peerconnection created, if this is an answer please use createAnswer")
                    return
                }

                let sdpString: String! = jsep["sdp"].string
                var type: RTCSdpType! = RTCSdpType.offer
                if jsep["type"].rawString()! == "offer" {
                    type = RTCSdpType.offer
                } else {
                    type = RTCSdpType.answer
                }
                let sdp: RTCSessionDescription! = RTCSessionDescription(type: type, sdp: sdpString)
                self._pc.setRemoteDescription(sdp) { (error) in
                    if let err = error {
                        print("Failed to set remote offer SDP")
                        //print("\(error)")
                        callbacks.onCallbackError("Failed to set remote offer SDP : \(err)")
                        return;
                    }
                    
                    //print("Succeed to set remote offer SDP")
                    if self._my_sdp == nil {
                        self.createSdpInternal(callbacks, false)
                    }
                }
            }
        }
    }

    open func hangUp() {
        
        if let callbacks = _callbacks {
            callbacks.onCleanup()
        }
        
        if let capturer = _capturer as? RTCCameraVideoCapturer {
            capturer.stopCapture()
        }

        if _pc != nil && (_pc.signalingState != RTCSignalingState.closed) {
            _pc?.close()
        }
        _pc = nil
        _started = false
        _my_sdp = nil
        if _data_channel != nil {
            _data_channel.close()
        }
        _data_channel = nil
        _trickle = true
        _ice_done = false
        _sdp_sent = false
    }

    public func detach() {
        hangUp()
        var obj: JSON! = JSON()
        
        let handler = DispatchQueue(label: "kr.co.grib.detach", qos: .userInteractive)
        handler.async {
            self._server.sendMessage(&obj, MediaServerMessageType.detach, self._id)
        }
    }

    public func getFeedId() -> Int64! {
        return _callbacks.getFeedId()
    }

    private func onLocalSdp(_ sdp: RTCSessionDescription!, _ callbacks: IPluginHandleWebRTCCallbacks!) {
        if _pc != nil {
            if _my_sdp == nil {
                _my_sdp = sdp
                _pc.setLocalDescription(sdp) { (error) in
                    if let err = error {
                        print("failed to set local sdp")
                        //print(err)
                        callbacks.onCallbackError("failed to set local sdp : \(err)")
                        return;
                    }
                    
                    //print("succeed to set local sdp")
                    if self._my_sdp == nil {
                        self.createSdpInternal(callbacks, false)
                    }
                }
            }
            if (!_ice_done) && (!_trickle) {
                return
            }
            if _sdp_sent {
                return
            }
            _sdp_sent = true
            
            var obj = JSON()
            obj["sdp"].string = _my_sdp.sdp
            obj["type"].string = _my_sdp.type == RTCSdpType.offer ? "offer" : "answer"
            callbacks.onSuccess(obj)
        }
    }

    private func sendTrickleCandidate(_ candidate: RTCIceCandidate!) {

        var message: JSON! = JSON()
        var cand: JSON! = JSON()
        if candidate == nil {
            cand["completed"].bool = true
        } else {
            cand["candidate"].string = candidate.sdp
            cand["sdpMid"].string = candidate.sdpMid
            cand["sdpMLineIndex"].int32 = candidate.sdpMLineIndex
        }
        message["candidate"] = cand
        _server.sendMessage(&message, MediaServerMessageType.trickle, _id)
    }

    private func sendSdp(_ callbacks: IPluginHandleWebRTCCallbacks!) {
        if _my_sdp != nil {
            _my_sdp = _pc.localDescription
            if !_sdp_sent {
                _sdp_sent = true

                var obj: JSON! = JSON()
                obj["sdp"].string = _my_sdp.sdp
                obj["type"].string = _my_sdp.type==RTCSdpType.offer ? "offer" : "answer"
                callbacks.onSuccess(obj)
            }
        }
    }
}

extension MediaServerPluginHandle: RTCPeerConnectionDelegate {
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        switch (stateChanged) {
        case .stable:
            print("peerConnection new signaling state: stable")
        case .haveLocalOffer:
            print("peerConnection new signaling state: haveLocalOffer")
        case .haveLocalPrAnswer:
            print("peerConnection new signaling state: haveLocalPrAnswer")
        case .haveRemoteOffer:
            print("peerConnection new signaling state: haveRemoteOffer")
        case .haveRemotePrAnswer:
            print("peerConnection new signaling state: haveRemktePrAnswer")
        case .closed:
            print("peerConnection new signaling state: closed")
        default:
            break
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch (newState) {
        case .disconnected:
            print("peerConnection new ice connection state: disconnected")
        case .connected:
            print("peerConnection new ice connection state: connected")
        case .new:
            print("peerConnection new ice connection state: new")
        case .checking:
            print("peerConnection new ice connection state: checking")
        case .closed:
            print("peerConnection new ice connection state: closed")
        case .failed:
            print("peerConnection new ice connection state: failed")
        default:
            break
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        switch (newState) {
        case .new:
            break
        case .gathering:
            break
        case .complete:
            if self._trickle == false {
                self._my_sdp = self._pc.localDescription
                self.sendSdp(self._sdp_cbks)
            } else {
                self.sendTrickleCandidate(nil)
            }
        default:
            break
        }
        print("peerConnection new gathering state: \(newState)")
    }
    
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if self._trickle == true {
            self.sendTrickleCandidate(candidate)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("peerConnection did add stream")
        self._remote_stream = stream
        self.onRemoteStream(stream)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("peerConnection did remove stream")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("peerDataChannel did open")
        _data_channel = dataChannel
        _data_channel.delegate = self
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnection should negotiate")
    }
    
    
}

extension MediaServerPluginHandle: RTCDataChannelDelegate {
    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        
    }
    
    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if buffer.isBinary {
            return
        }
        do {
            let data = try JSON(data: buffer.data)
            _callbacks.onData(data)
        } catch {
            print("exception occur in processing data on data channel")
        }
    }
    
    
}
