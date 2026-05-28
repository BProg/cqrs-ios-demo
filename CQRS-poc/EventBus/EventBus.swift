//
//  EventBus.swift
//  EventBus
//
//  Created by Ion Ostafi on 13.03.2025.
//

@preconcurrency import Combine
import Foundation

public typealias SendEventFn = @Sendable (any EventProtocol) -> Void

public final class EventBus: Sendable {
    public init() {}
    public static let shared = EventBus()
    private let sender = PassthroughSubject<any EventProtocol, Never>()
    public var all: AnyPublisher<any EventProtocol, Never> {
        sender
            .eraseToAnyPublisher()
    }

    public func send(_ event: any EventProtocol) {
        #if DEBUG
            print("[E] \(event.source) - \(event.name)")
        #endif
        sender.send(event)
    }

    public func receive<T: EventProtocol>(_: T.Type) -> AnyPublisher<T, Never> {
        all
            .compactMap { $0 as? T }
            .eraseToAnyPublisher()
    }

    public func receiveOnMain<T: EventProtocol>(_: T.Type) -> AnyPublisher<T, Never> {
        all
            .compactMap { $0 as? T }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public func receive<T: EventProtocol>(
        _: T.Type,
        where condition: @escaping (T) -> Bool
    ) -> AnyPublisher<T, Never> {
        all
            .compactMap { $0 as? T }
            .filter { condition($0) }
            .eraseToAnyPublisher()
    }

    public func task<T: EventProtocol>(
        _: T.Type,
        perform action: @escaping @Sendable (T.Payload) async -> Void
    ) -> AnyCancellable {
        var task: Task<Void, Never>? = nil
        return receive(T.self)
            .handleEvents(receiveCancel: { task?.cancel() })
            .sink { event in
                let payload = event.payload
                task = Task(name: "eventbus.task", priority: .background) {
                    await action(payload)
                }
            }
    }
}
