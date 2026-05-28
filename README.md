# CQRS-poc

This project is a lightweight CQRS demo in SwiftUI showing strict separation between writes (commands) and reads (query model).

It is designed as a full app lifecycle reference: command intake, domain decisioning, event publication, projection updates, and reactive UI query refresh, all in one flow.

At its core, this is a true event-driven architecture where business state changes are communicated through events, and the read side converges through true eventual consistency.

## Main Architectural Focus

- The UI does not mutate domain state directly.
- The UI reads from an aggregated read model.
- The UI writes by dispatching commands.
- Domain services handle commands and emit domain events.
- Aggregation services consume events and update a denormalized read model.
- SwiftUI auto-refreshes because `@Query` is bound to SwiftData models (Core Data-backed persistence).

## Architecture Overview

### Write Side (Command Side)

- Commands are represented in `Command` and published through the `EventBus`.
- `ProductCardView` dispatches:
  - `considerProduct(productId:)`
  - `unconsiderProduct(productId:)`
- `WishlistService` subscribes to those command events, applies write-side repository changes, then publishes domain events:
  - `productConsidered(productId:)`
  - `productUnconsidered(productId:)`

### Event Processing / Projection

- `AggregationService` subscribes to domain events.
- On startup (`boot()`), it builds the initial projection from:
  - products repository
  - considered products repository
- On each event, it incrementally updates the read model in `SwiftDataAggregatedProductsRepository`.

### Read Side (Query Side)

- The screen reads only from `AggregatedUserProduct` (read model).
- `ProductsListView` uses `@Query` over the aggregated model container.
- Because `@Query` is directly bound to SwiftData entities, view updates are automatic when projections change.

## Request Flow

```mermaid
flowchart LR
    V[SwiftUI View] -->|dispatch Command| B[EventBus]
    B --> S[WishlistService]
    S -->|write| W[(Write Repositories)]
    S -->|publish Domain Event| B
    B --> A[AggregationService]
    A -->|project/update| R[(Aggregated Read Model)]
    R -->|@Query| V
```

## Key Components

- `EventBus`: in-process async event transport for commands and domain events.
- `WishlistService`: command handler for wishlist mutations.
- `AggregationService`: projection builder/updater for read models.
- `SwiftDataProductsRepository`: source products.
- `SwiftDataWishlistRepository`: write-side user consideration state.
- `SwiftDataAggregatedProductsRepository`: denormalized read model for the UI.
- `DIContainer`: composes repositories/services and wires bus subscriptions.

## Why This Matters

This design keeps the UI simple and reactive while enforcing a clean write/read split:

- writes are explicit (commands)
- business changes are observable (events)
- reads are optimized for display (aggregated projection)
- SwiftUI stays declarative and auto-updating through `@Query`

From a product perspective, this gives you a practical blueprint for real-world apps that need resilient workflows, independently scalable read/write concerns, and transparent consistency behavior over time.
