//
//  EventBase.swift
//  EventBus
//
//  Created by Ion Ostafi on 20.12.2024.
//

import Combine
import Foundation

public protocol EventProtocol: CustomStringConvertible {
    associatedtype Payload: Sendable

    var generationDate: Date { get }
    var id: UUID { get }
    var name: String { get }
    var source: String { get }
    var payload: Payload { get }
}

open class EventBase<Payload: Sendable>: EventProtocol {
    public let generationDate: Date = Date()
    public let id: UUID = .init()
    public let name: String
    public let source: String
    public let payload: Payload

    public init(_ payload: Payload, _ source: String = #file, _ line: Int = #line) {
        self.source = (URL(string: source)?.lastPathComponent ?? source) + ":\(line)"
        self.payload = payload
        name = String(describing: type(of: self))
    }

    public var description: String {
        """
        Event: \(name);\(id);\(source);\(generationDate.formatted())
            Payload: \(String(describing: payload))
        """
    }
}

open class EmptyEvent: EventBase<Void> {
    public init(_ source: String = #file) {
        super.init((), source)
    }

    override public var description: String {
        """
        [EmptyEvent] \(name)
        id: \(id)
        source: \(source)
        date: \(generationDate)
        """
    }
}
