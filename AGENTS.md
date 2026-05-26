# Repository Guidelines

## Project Structure & Module Organization
`RSMS/` contains the iOS app source. Core app entry points live in `RSMS/App/`, shared domain models and app state in `RSMS/Core/`, networking and Supabase integration in `RSMS/Networking/`, and reusable UI in `RSMS/UI/`. Feature code is grouped under `RSMS/Features/` by role or flow, for example `Features/Login`, `Features/SalesAssociate`, and `Features/InventoryController`. Mock fixtures live in `RSMS/MockData/`, and image/color assets live in `RSMS/Assets.xcassets/`. `RSMS.xcodeproj/` is the Xcode project. Legacy folders such as `RSMS/Inventory Controller/` and `RSMS/Sales Associate/` should not be expanded for new work.

## Build, Test, and Development Commands
Open the project in Xcode with `open RSMS.xcodeproj`. Build from the command line with `xcodebuild -project RSMS.xcodeproj -scheme RSMS -destination 'generic/platform=iOS' build`. Use Xcode previews or run the `RSMS` scheme in Simulator for UI validation. There is currently no committed test target, so `xcodebuild test` will require adding one first.

## Coding Style & Naming Conventions
Follow existing Swift conventions: 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties and methods, and one primary type per file named to match it, such as `LoginViewModel.swift`. Prefer feature-local `View` and `ViewModel` pairs under the relevant `Features/` folder. Keep shared business data access in `DataStore` or `Networking/` helpers rather than embedding it in SwiftUI views. Use `// MARK:` to separate sections in longer files.

## Testing Guidelines
This repository currently has no `XCTest` target. For new logic-heavy work, add unit tests alongside a new `RSMSUITests` or `RSMSTests` target and name files `FeatureNameTests.swift`. Prioritize view models, data transformations, and Supabase-facing code. Until test infrastructure exists, include manual verification steps in pull requests.

## Commit & Pull Request Guidelines
Recent history uses short messages such as `ui change` and `updated`; improve this by using concise imperative summaries like `Add stock reconciliation view model`. Keep pull requests focused, describe user-visible changes, list validation steps, and attach screenshots for SwiftUI UI changes. Link related issues or tasks when available and note any mock-data or backend assumptions.

## Security & Configuration Tips
Do not hardcode Supabase credentials or environment-specific values in views or models. Keep secrets isolated to configuration files and verify any new network code continues to flow through `SupabaseClient` and `SupabaseAuth`.
