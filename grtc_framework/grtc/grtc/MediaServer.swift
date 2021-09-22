//
//  MediaServer.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//
 
import Foundation
import WebRTC
import SwiftyJSON

open class MediaServer : IMediaServerMessageObserver, IMediaServerSessionCreationCallbacks, IMediaServerAttachPluginCallbacks {
    private let _string_generator: RandomString! = RandomString()
    private var _attached_plugins: Dictionary<Int64, MediaServerPluginHandle> = Dictionary<Int64, MediaServerPluginHandle>()
    private var _attached_plugins_lock = NSLock()
    private var _transactions: Dictionary<String, ITransactionCallbacks> = Dictionary<String, ITransactionCallbacks>()
    private var _transactions_lock = NSLock()
    public var _server_uri: String!
    public var _gateway_observer: IMediaServerGatewayCallbacks!
    public var _ice_servers: [RTCIceServer]!
    public var _ipv6_support: Bool!
    public var _max_poll_events: Int32
    private var _width: Int32 = 0
    private var _height: Int32 = 0
    private var _fps: Int32 = 0
    private var _code: String!
    private var _session_id: Int64!
    private var _connected: Bool!
    private var _server_connection: IMediaServerMessenger!
    private var _keep_alive: DispatchQueue!

    public init(_ gatewayCallbacks: IMediaServerGatewayCallbacks!) {
        _gateway_observer = gatewayCallbacks
        _server_uri = _gateway_observer.getServerUri()
        _ice_servers = _gateway_observer.getIceServers()
        _ipv6_support = _gateway_observer.getIpv6Support()
        _max_poll_events = _gateway_observer.getMaxPollEvents()
        _width = _gateway_observer.getWidth()
        _height = _gateway_observer.getHeight()
        _fps = _gateway_observer.getFPS()
        _code = _gateway_observer.getCode()
        _connected = false
        _session_id = -1
        _server_connection = MediaServerMessagerFactory.createMessager(_server_uri, self)
    }

    private func putNewTransaction(_ transactionCallbacks: ITransactionCallbacks!) -> String! {
        var transaction: String! = _string_generator.randomString(12)

        do {
            _transactions_lock.lock(); defer { _transactions_lock.unlock() }
            while _transactions.keys.contains(transaction) {
                transaction = _string_generator.randomString(12)
            }
            _transactions[transaction] = transactionCallbacks
        }

        return transaction
    }

    private func createSession() {
        var obj: JSON = JSON()
        obj["janus"].string = MediaServerMessageType.create.rawValue
        let cb: ITransactionCallbacks! = MediaServerTransactionCallbackFactory.createNewTransactionCallback(self, TransactionType.create)
        let transaction: String! = putNewTransaction(cb)
        obj["transaction"].string = transaction
        
        
        if let dic = obj.dictionaryObject {
            _server_connection.sendMessage(dic)
        }
    }

    open func run() {
        while _connected {
            if _server_connection.getMessengerType() != MediaServerMessengerType.websocket {
                if (!_connected) || (_server_connection.getMessengerType() == MediaServerMessengerType.websocket) {
                    return
                }
                _server_connection.longPoll(_session_id)
            } else {
                
                sleep(25000)
                
                if (!_connected) || (_server_connection.getMessengerType() != MediaServerMessengerType.websocket) {
                    return
                }
                var obj: JSON! = JSON()
                obj["janus"].string = MediaServerMessageType.keepalive.rawValue
                if _server_connection.getMessengerType() == MediaServerMessengerType.websocket {
                    obj["session_id"].int64 = _session_id
                }
                obj["transaction"].string = _string_generator.randomString(12)
                if let dic = obj.dictionaryObject {
                    _server_connection.sendMessage(dic, _session_id)
                }
            }
        }
    }

    open func isConnected() -> Bool! {
        return _connected
    }

    open func getSessionId() -> Int64! {
        return _session_id
    }

    open func Attach(_ callbacks: IMediaServerPluginCallbacks!) {
        if let plugin = callbacks.getPlugin() {
            let attach = DispatchQueue(label: "kr.co.grib.attach", qos: .userInteractive)
            attach.async {
                var obj: JSON! = JSON()
                obj["janus"].string = MediaServerMessageType.attach.rawValue
                obj["plugin"].string = plugin.rawValue
                if self._server_connection.getMessengerType() == MediaServerMessengerType.websocket {
                    obj["session_id"].int64 = self._session_id
                }
                let tcb: ITransactionCallbacks! = MediaServerTransactionCallbackFactory.createNewTransactionCallback(self, TransactionType.attach, plugin, callbacks)
                let transaction: String! = self.putNewTransaction(tcb)
                obj["transaction"].string = transaction
                if let dic = obj.dictionaryObject {
                    self._server_connection.sendMessage(dic, self._session_id)
                }
            }
        }
    }

    open func Destroy() {
        _server_connection.disconnect()
        _keep_alive = nil
        _connected = false
        _gateway_observer.onDestroy()
        
        do {
            _attached_plugins_lock.lock(); defer { _attached_plugins_lock.unlock() }
            for handle in _attached_plugins.values {
                handle.detach()
            }
        }
        
        do {
            _transactions_lock.lock(); defer { _transactions_lock.unlock() }
            for key in _transactions.keys {
                _transactions.removeValue(forKey: key)
            }
        }
        
        
    }

    open func Connect() {
        _server_connection.connect()
    }

    open func Detach(_ id: Int64!) {
        var attachedPlugin: MediaServerPluginHandle?
        
        do {
            _attached_plugins_lock.lock(); defer {_attached_plugins_lock.unlock() }
            for (_, v) in _attached_plugins {
                if v.getFeedId()==id {
                    attachedPlugin = v
                }
            }
        }
        
        if let v = attachedPlugin {
            v.detach()
        }
    }

    open func newMessageForPlugin(_ message: String!, _ pluginid: Int64!) {
        var handle: MediaServerPluginHandle! = nil
        
        do {
            _attached_plugins_lock.lock(); defer { _attached_plugins_lock.unlock() }
            handle = _attached_plugins[pluginid]
        }
        
        if handle != nil {
            handle.onMessage(message)
        }
    }

    public func onCallbackError(_ error: String!) {
        _gateway_observer.onCallbackError(error)
    }

    open func sendMessage(_ msg: inout JSON!, _ type: MediaServerMessageType!, _ handle: Int64!) {
        msg["janus"].string = type.rawValue
        if _server_connection.getMessengerType() == MediaServerMessengerType.websocket {
            msg["session_id"].int64 = _session_id
            msg["handle_id"].int64 = handle
        }
        msg["transaction"].string = _string_generator.randomString(12)
        
        if let dic = msg.dictionaryObject {
            if _connected {
                _server_connection.sendMessage(dic, _session_id, handle)
            }
        }
        
        if type == MediaServerMessageType.detach {
            do {
                _attached_plugins_lock.lock(); defer { _attached_plugins_lock.unlock() }
                if _attached_plugins.keys.contains(handle) {
                    _attached_plugins.removeValue(forKey: handle)
                }
            }
        }
    }

    // TODO not sure if the send message functions should be Asynchronous
    open func sendMessage(_ type: TransactionType!, _ handle: Int64!, _ callbacks: IPluginHandleSendMessageCallbacks!, _ plugin: MediaServerSupportedPluginPackages!) {
        let msg: JSON! = callbacks.getMessage()
        if msg != nil {
            var newMessage: JSON! = JSON()
            newMessage["janus"].string = MediaServerMessageType.message.rawValue
            if _server_connection.getMessengerType() == MediaServerMessengerType.websocket {
                newMessage["session_id"].int64 = _session_id
                newMessage["handle_id"].int64 = handle
            }
            let cb: ITransactionCallbacks! = MediaServerTransactionCallbackFactory.createNewTransactionCallback(self, TransactionType.plugin_handle_message, plugin, callbacks)
            let transaction: String! = putNewTransaction(cb)
            newMessage["transaction"].string = transaction
            if msg["message"].exists() {
                newMessage["body"].object = msg["message"].object
            }
            if msg["jsep"].exists() {
                newMessage["jsep"].object = msg["jsep"].object
            }
            
            if let dic = newMessage.dictionaryObject {
                _server_connection.sendMessage(dic, _session_id, handle)
            }
        }
    }

    open func sendMessage(_ type: TransactionType!, _ handle: Int64!, _ callbacks: IPluginHandleWebRTCCallbacks!, _ plugin: MediaServerSupportedPluginPackages!) {

        var msg: JSON! = JSON()
        msg["janus"].string = MediaServerMessageType.message.rawValue
        if _server_connection.getMessengerType() == MediaServerMessengerType.websocket {
            msg["session_id"].int64 = _session_id
            msg["handle_id"].int64 = handle
        }
        let cb: ITransactionCallbacks! = MediaServerTransactionCallbackFactory.createNewTransactionCallback(self, TransactionType.plugin_handle_webrtc_message, plugin, callbacks)
        let transaction: String! = putNewTransaction(cb)
        msg["transaction"].string = transaction
        if let jsep = callbacks.getJsep() {
            msg["jsep"].object = jsep.object
        }
        if let dic = msg.dictionaryObject {
            _server_connection.sendMessage(dic, _session_id, handle)
        }
    }

    // region MessageObserver
    open func receivedNewMessage(_ obj: JSON!) {
        
        if let debug = obj {
            print("-------receivedNewMessage--------")
            print(debug)
        }
        
        let type: MediaServerMessageType! = MediaServerMessageType(rawValue: obj["janus"].rawString()!)
        var transaction: String! = nil
        var sender: Int64! = nil
        if obj["transaction"].exists() {
            transaction = obj["transaction"].string
        }
        if obj["sender"].exists() {
            sender = obj["sender"].int64
        }
        var handle: MediaServerPluginHandle! = nil
        if sender != nil {
            _attached_plugins_lock.lock(); defer { _attached_plugins_lock.unlock() }
            handle = _attached_plugins[sender];
        }
        switch type {
        case .ack,
             .success,
             .error :
                if transaction != nil {
                    var cb: ITransactionCallbacks! = nil
                    do {
                        _transactions_lock.lock(); defer { _transactions_lock.unlock() }
                        cb = _transactions[transaction]
                        if cb != nil {
                            _transactions.removeValue(forKey: transaction)
                        }
                    }
                    if cb != nil {
                        cb.reportSuccess(obj)
                        _transactions.removeValue(forKey: transaction)
                    }
                }
                if handle != nil {
                    var plugindata: JSON! = nil
                    if obj["plugindata"].exists() {
                        plugindata = obj["plugindata"]
                    }
                    if plugindata != nil {
                        var data: JSON! = nil
                        var jsep: JSON! = nil
                        if plugindata["data"].exists() {
                            data = plugindata["data"]
                        }
                        if obj["jsep"].exists() {
                            jsep = obj["jsep"]
                        }
                        handle.onMessage(data, jsep)
                    }
                }
        case .hangup:
            if handle != nil {
                handle.hangUp()
            }
        case .detached:
            if handle != nil {
                handle.onDetached()
                handle.detach()
            }
        case .event:
            if handle != nil {
                var plugindata: JSON! = nil
                if obj["plugindata"].exists() {
                    plugindata = obj["plugindata"]
                }
                if plugindata != nil {
                    var data: JSON! = nil
                    var jsep: JSON! = nil
                    if plugindata["data"].exists() {
                        data = plugindata["data"]
                    }
                    if obj["jsep"].exists() {
                        jsep = obj["jsep"]
                    }
                    handle.onMessage(data, jsep)
                }
            }
        default:
            break;
        }
    }

    open func onOpen() {
        createSession()
    }

    open func onClose() {
        _connected = false
        _gateway_observer.onCallbackError("Connection to Media Server is closed")
    }

    open func onError(_ error: String!) {
        _gateway_observer.onCallbackError("Error connected to Media Server. Exception: \(String(describing: error))")
    }

    open func onSessionCreationSuccess(_ obj: JSON!) {
        _session_id = obj["data"]["id"].int64
        _keep_alive = DispatchQueue(label: "kr.co.grib.queue", qos: .background)
        _keep_alive.async {
            self.run()
        }
        _connected = true
        _gateway_observer.onSuccess()
    }

    open func attachPluginSuccess(_ obj: JSON!, _ plugin: MediaServerSupportedPluginPackages!, _ callbacks: IMediaServerPluginCallbacks!) {
        let handle = obj["data"]["id"].int64
        let pluginHandle: MediaServerPluginHandle! = MediaServerPluginHandle(self, _code, plugin, handle, callbacks, _width, _height, _fps)
        do {
            _attached_plugins_lock.lock(); defer { _attached_plugins_lock.unlock() }
            _attached_plugins[handle!] = pluginHandle
        }
        callbacks.success(pluginHandle)
    }

    class RandomString {
        open func randomString(_ length: Int32!) -> String! {

            let allowedChars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            let allowedCharsCount = UInt32(allowedChars.count)
            var randomString = ""

            for _ in 0 ..< length {
                let randomNum = Int(arc4random_uniform(allowedCharsCount))
                let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
                let newCharacter = allowedChars[randomIndex]
                randomString += String(newCharacter)
            }
            return randomString
        }
    }
}
