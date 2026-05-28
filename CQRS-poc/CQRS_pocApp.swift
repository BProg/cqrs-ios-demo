//
//  CQRS_pocApp.swift
//  CQRS-poc
//
//  Created by ionostafi on 5/27/26.
//

import SwiftUI
import SwiftData

@main
struct CQRS_pocApp: App {
    private let aggregatedModelContainer: ModelContainer
    private let diContainer: DIContainer

    init() {
        let di = DIContainer()
        self.diContainer = di
        self.aggregatedModelContainer = di.viewModelsContainer
        di.aggregationService.boot()
    }

    var body: some Scene {
        WindowGroup {
            ProductsListView()
                .eventBus(diContainer.eventBus)
        }
        .modelContainer(aggregatedModelContainer)
    }
}
