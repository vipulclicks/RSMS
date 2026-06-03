# Repository Guidelines

## Project Structure & Module Organization
This is a SwiftUI iOS app organized under `RSMS/` inside the `RSMS.xcodeproj` workspace. Feature code is grouped by domain:

- `App/` for app entry points such as `RSMSApp.swift` and `ContentView.swift`
- `Features/` for user-facing flows like `BoutiqueManager`, `SalesAssociate`, `InventoryController`, `StoreCompliance`, and `Planograms`
- `Core/` for shared models, view models, theme, and utilities
- `UI/` for reusable components, modifiers, and styles
- `Networking/` for Supabase configuration and client/auth code
- `Assets.xcassets/` for colors and app icons

Keep new files in the matching feature folder and name them after the screen or view model they represent.

## Build, Test, and Development Commands
- `open RSMS.xcodeproj` opens the project in Xcode for daily development.
- `xcodebuild -project RSMS.xcodeproj -scheme RSMS -configuration Debug build` performs a local command-line build.
- `xcodebuild -list -project RSMS.xcodeproj` shows the available scheme and build configurations.

There is no visible XCTest target in the repository at the moment, so `xcodebuild test` is not currently part of the standard workflow.

## Coding Style & Naming Conventions
Follow standard SwiftUI conventions used in the repo:

- Use `PascalCase` for types (`BoutiqueManagerHomeView`) and `camelCase` for methods, properties, and view model state.
- Prefer one primary type per file and keep file names aligned with that type.
- Use 4-space indentation and keep SwiftUI views small by extracting reusable UI into `UI/Components/`.
- No formatter or linter is configured in-repo, so match the surrounding style rather than introducing new tooling assumptions.

## Testing Guidelines
When tests are added, place them in a dedicated test target and name files after the unit under test, for example `LookbookViewModelTests.swift`. Focus on view model logic, data-store behavior, and Supabase-facing code paths. Until then, verify changes by building the app and manually exercising the affected screen in Xcode.

## Commit & Pull Request Guidelines
Recent history uses short, imperative subjects and occasional feature tags, such as `BOPIS` or `feat(lookup): ...`. Keep commits focused on one change. For pull requests:

- describe the user-visible behavior change
- note any Supabase or schema impact
- include screenshots or screen recordings for UI updates
- mention how you verified the change

## Security & Configuration Tips
Treat `RSMS/Networking/SupabaseConfig.swift` as configuration, not a place for secrets. Avoid committing environment-specific credentials or local backend URLs unless they are meant to be shared.
