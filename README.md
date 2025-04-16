# iOS Document Manager

An advanced iOS document management application that provides seamless online and offline document handling with robust Core Data persistence and a clean MVVM architectural pattern.

## Features

- **Document Management**: Create, view, edit, and delete documents
- **Offline Support**: Full offline functionality with automatic synchronization when online
- **Favorites**: Mark documents as favorites for quick access
- **File Types**: Support for various file types (TXT, DOCX, PDF, XLSX, PPTX)
- **Modern UI**: Clean, intuitive interface with SwiftUI
- **Dark Mode**: Full support for light and dark modes
- **Animations**: Delightful animations including confetti effect for document uploads

## Architecture

This application is built using the MVVM (Model-View-ViewModel) architecture pattern for clean separation of concerns:

- **Models**: Core Data entities for documents
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and data handling

## Technical Details

- **Swift**: Built with Swift 5.5+
- **SwiftUI**: Modern declarative UI framework
- **UIKit Integration**: Where needed for specialized components
- **Core Data**: For robust local data persistence
- **Network Layer**: URLSession-based API client for server communication
- **Error Handling**: Comprehensive error handling throughout the app
- **Dependency Injection**: For improved testability

## Screens

### Main Tabs

- **Home**: View all documents with search and filtering
- **Favorites**: Quick access to favorite documents

### Document Functionality

- **Document List**: Swipe actions for favorite/delete
- **Document Detail**: View and edit document contents
- **Create Document**: Form for adding new documents with file type selection
- **Upload Animation**: Progress indication and celebration on completion

## Core Components

### Services

- **CoreDataStack**: Manages persistent storage
- **APIService**: Handles network requests
- **SyncService**: Coordinates online/offline sync
- **NetworkMonitor**: Tracks network connectivity status

### View Models

- **DocumentListViewModel**: Manages document collections
- **DocumentViewModel**: Represents individual documents

## Getting Started

1. Clone the repository
2. Open `DocumentManager.xcodeproj` in Xcode 13+
3. Build and run on an iOS 15+ simulator or device

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## License

This project is available under the MIT license.