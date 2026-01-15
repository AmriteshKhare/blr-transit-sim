# BLR Transit Engine - iOS App

A native iOS app for the Bengaluru Transit Simulation Engine, built with UIKit and Apple's **Liquid Glass** design language.

## Features

- 🚇 **Metro Route Visualization**: MapKit integration with metro line polylines
- 🔍 **Station Search**: Searchable picker with fuzzy filtering
- 📊 **Time Comparison**: Glass-morphic results cards comparing Metro vs Road
- ✨ **Liquid Glass UI**: Native iOS 26 materials (`UIVisualEffectView`)

## Project Structure

```
BLRTransitApp/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── Info.plist
├── Models/
│   ├── Station.swift
│   ├── MetroLine.swift
│   └── Graph.swift
├── Services/
│   ├── PathfindingService.swift
│   ├── RoadTimeCalculator.swift
│   └── StationDataLoader.swift
├── Views/
│   ├── MainViewController.swift
│   ├── ControlPanelView.swift
│   ├── ResultsCardView.swift
│   └── StationPickerViewController.swift
├── Extensions/
│   └── UIView+Glass.swift
└── Resources/
    └── Assets.xcassets/
```

## Setup

1. Open in Xcode 16+ (requires iOS 18+ for Liquid Glass)
2. Create a new iOS App project named `BLRTransitApp`
3. Replace the generated files with these source files
4. Build and run on Simulator or device

## Requirements

- Xcode 16+
- iOS 18.0+ (for full Liquid Glass support)
- Swift 5.9+
