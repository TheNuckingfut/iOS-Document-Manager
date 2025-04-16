import UIKit

// The @main annotation in AppDelegate.swift defines the entry point
// This file is needed because we defined an executable target in Package.swift
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)