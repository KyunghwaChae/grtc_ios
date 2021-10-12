import Foundation
import Alamofire
import SwiftyJSON

open class MediaServerRestAPI : IMediaServerMessenger {
    private let handler: IMediaServerMessageObserver!
    private let uri: String!
    private var session_id: Int64!
    private var handle_id: Int64!
    private var resturi: String!
    private let type: MediaServerMessengerType! = MediaServerMessengerType.restful
    private var waitPoll: Bool = false
    //private let waitGroup: DispatchGroup = DispatchGroup()
    private var connected: Bool = false

    public init(_ uri: String!, _ handler: IMediaServerMessageObserver!) {
        self.handler = handler
        self.uri = uri
        self.resturi = ""
    }

    open func getMessengerType() -> MediaServerMessengerType! {
        return type
    }

    open func connect() {
        self.handler.onOpen()
        self.connected = true
        /*
        AF.request(uri, method: .get, parameters: [:], encoding: URLEncoding.default, headers: nil)
            .responseData { response in
                switch response.result {
                case .success:
                    self.handler.onOpen()
                    self.connected = true
                case .failure:
                    self.handler.onError("failed to connect")
                    self.connected = false
                }
            }
         */
    }

    open func disconnect() {
        // todo
        //self.waitGroup.leave()
        self.connected = false
    }

    open func longPoll(_ sessionId: Int64!) {

        if self.resturi.isEmpty {
            self.resturi = uri
        }
        self.waitPoll = true
        //waitGroup.enter()
        
        let timestamp = NSDate().timeIntervalSince1970
        let reqUri = uri + "/\(sessionId as Int64)?rid=\(timestamp as Double)&maxev=10"
        
        
        AF.request(reqUri, method: .get)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    //self.waitGroup.leave()
                    self.waitPoll = false
                    let json = JSON(value)
                    for (_,subJson): (String, JSON) in json {
                        //let recv = DispatchQueue(label: "kr.co.grib.recv", qos: .userInitiated)
                        //recv.async {
                            self.receivedMessage(subJson)
                        //}
                    }
                case .failure(let error):
                    self.waitPoll = false
                    //self.waitGroup.leave()
                    //let recv = DispatchQueue(label: "kr.co.grib.error", qos: .userInitiated)
                    //recv.async {
                        self.handler.onError(error.localizedDescription)
                    //}
                }
            }
        
        while waitPoll==true && connected==true {
            usleep(20)
        }
        //self.waitGroup.wait();
    }
    
    open func sendMessage(_ message: [String: Any]!) {
        if resturi.isEmpty {
            resturi = uri
        }
        
        /*
        if let debug = message {
            print("-------sendNewMessage-------")
            print(resturi)
            print(debug)
        }
        */
        
        AF.request(resturi, method: .post, parameters: message, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    self.receivedMessage(json)
                    //self.handler.receivedNewMessage(json)
                case .failure(let error):
                    self.handler.onError(error.localizedDescription)
                }
            }

    }

    open func sendMessage(_ message: [String: Any]!, _ session_id: Int64!) {
        self.session_id = session_id
        resturi = ""
        resturi = uri + "/\(session_id as Int64)"
        sendMessage(message)
    }

    open func sendMessage(_ message: [String: Any]!, _ session_id: Int64!, _ handle_id: Int64!) {
        self.session_id = session_id
        self.handle_id = handle_id
        resturi = ""
        resturi = uri + "/\(session_id as Int64)/\(handle_id as Int64)"
        sendMessage(message)
    }

    open func receivedMessage(_ message: JSON!) {
        self.handler.receivedNewMessage(message)
    }
}
