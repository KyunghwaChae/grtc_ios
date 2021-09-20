//
//  File.swift
//  grtc
//
//  Created by Andrew Chae on 2021/08/16.
//

import Foundation

extension StringProtocol {
    func distance(of element: Element) -> Int? { firstIndex(of: element)?.distance(in: self) }
    func distance<S: StringProtocol>(of string: S) -> Int? { range(of: string)?.lowerBound.distance(in: self) }
}
extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
}
extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int { string.distance(to: self) }
}

public class MediaServerMessagerFactory {
    public static func createMessager(_ uri: String!, _ handler: IMediaServerMessageObserver!) -> IMediaServerMessenger! {
        if let index = uri.distance(of: "ws") {
            if index == 0 {
                return MediaServerWSAPI(uri, handler)
            }
        }
        return MediaServerRestAPI(uri, handler)
    }
}
