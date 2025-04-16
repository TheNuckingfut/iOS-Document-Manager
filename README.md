# iOS Document Manager

An advanced iOS document management application that provides seamless online and offline document handling with robust Core Data persistence and a clean MVVM architectural pattern.

## Key Features

- **MVVM Architecture**: Clean separation of concerns with Models, Views, and ViewModels
- **Core Data Integration**: Robust local persistence for document storage
- **Online/Offline Sync**: Work offline and sync changes when connectivity returns
- **Document CRUD Operations**: Create, read, update, and delete documents
- **Favorites**: Mark documents as favorites for quick access
- **Search**: Find documents by name with real-time filtering
- **Beautiful Animations**: Playful document upload animations with confetti celebration
- **Dark Mode Support**: Full support for iOS light and dark modes

## Technical Highlights

- SwiftUI for modern UI implementation
- Core Data for persistence
- Combine framework for reactive programming
- Network state monitoring
- Smart synchronization strategies
- Comprehensive error handling

## Project Structure

```
DocumentManager/
├── Models/               # Core data models and entities
├── Services/             # CoreDataStack, API, Network, Sync services
├── Utilities/            # Helper utilities and extensions
├── ViewModels/           # MVVM view models
└── Views/                # SwiftUI views including animations
    └── Animations/       # Custom animations (ConfettiView, UploadAnimationView)
```

## Getting Started

1. Clone the repository
2. Open the project in Xcode
3. Build and run the project on an iOS simulator or device

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+