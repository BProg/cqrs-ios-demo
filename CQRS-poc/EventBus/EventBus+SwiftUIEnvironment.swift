import Foundation
import SwiftUI

extension EnvironmentValues {
    @Entry public var bus: EventBus = .shared
}

extension View {
    public func eventBus(_ eventBus: EventBus) -> some View {
        environment(\.bus, eventBus)
    }
}
