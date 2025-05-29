# MakeCampaign

A SwiftUI application for creating and managing donation campaign promotional materials, built with The Composable Architecture (TCA).

## Intro

MakeCampaign is an iOS app designed to help users create, manage, and generate promotional pictures for donation campaigns (збори). The app provides:

- **Campaign Management**: Create and organize multiple donation campaigns
- **Template Selection**: Choose from various promotional templates
- **Campaign Details**: Manage detailed information for each campaign
- **Data Persistence**: Automatically saves campaign data locally

The app is built using modern iOS development practices with SwiftUI for the user interface and The Composable Architecture (TCA) for state management and business logic.

## Download

[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/ua/app/%D1%80%D0%BE%D0%B1%D0%B8%D0%B7%D0%B1%D1%96%D1%80-%D1%88%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD%D0%B8-%D0%B4%D0%BB%D1%8F-%D0%B7%D0%B1%D0%BE%D1%80%D1%96%D0%B2/id6746411335)

## Screenshots

<div align="center">
  <img src="screenshots/1.PNG" width="250" alt="Campaign List View"/>
  <img src="screenshots/2.PNG" width="250" alt="Campaign Details Form"/>
  <img src="screenshots/3.PNG" width="250" alt="Template Selection"/>
</div>

## Installation

### Requirements
- Xcode 15.0 or later
- iOS 16.0 or later
- Swift 5.9 or later

### Setup
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd MakeCampaign
   ```

2. Open the project in Xcode:
   ```bash
   open MakeCampaign.xcodeproj
   ```

3. Build and run the project:
   - Select your target device/simulator
   - Press `Cmd + R` or click the Run button

### Dependencies
The project uses The Composable Architecture (TCA) for state management. Ensure all Swift Package Manager dependencies are resolved in Xcode.

## Data Flow

The application follows The Composable Architecture pattern, providing a unidirectional data flow:

### Architecture Overview

```
User Action → Store → Reducer → State Change → View Update
```

### Detailed Data Flow Scheme

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AppFeature (Root)                        │
│  ┌─────────────────┐  ┌─────────────────────────────────────────┐  │
│  │ Navigation      │  │ Auto-Save System                        │  │
│  │ StackState      │  │ • Debounced JSON save (1 second)       │  │
│  │ • details       │  │ • Encodes campaigns to campaigns.json  │  │
│  │ • template      │  │ • Triggers on any state change         │  │
│  └─────────────────┘  └─────────────────────────────────────────┘  │
│                                    │                                │
│                    ┌───────────────▼───────────────┐                │
│                    │       CampaignsFeature        │                │
│                    └───────────────┬───────────────┘                │
└─────────────────────────────────────┼─────────────────────────────────┘
                                      │
        ┌─────────────────────────────▼─────────────────────────────┐
        │                CampaignsFeature                          │
        │                                                          │
        │  Data Loading:                                           │
        │  ┌─────────────────────────────────────────────────────┐ │
        │  │ Init → JSONDecoder.decode(campaigns.json)           │ │
        │  │ onViewInitialLoad → Parallel API calls             │ │
        │  │   ├─ TaskGroup for jar link campaigns             │ │
        │  │   └─ jarApiClient.loadProgress(jarLink)            │ │
        │  └─────────────────────────────────────────────────────┘ │
        │                                                          │
        │  User Actions:                                           │
        │  • createCampaign → Present modal                        │
        │  • campaignSelected → Navigate to details               │
        │                                                          │
        │  State Management:                                       │
        │  • campaigns: IdentifiedArrayOf<Campaign>               │
        │  • @PresentationState addCampaign                       │
        │  • @PresentationState openCampaign                      │
        └─────────────────┬────────────────────────────────────────┘
                          │
    ┌─────────────────────▼─────────────────────┐
    │           CampaignDetailsFeature          │
    │                                           │
    │  Complex State Management:                │
    │  ┌─────────────────────────────────────┐  │
    │  │ @BindingState campaign: Campaign    │  │
    │  │ @BindingState focus: Field?         │  │
    │  │ validationErrors: ValidationErrors  │  │
    │  │ selectedImage: SelectedImage?       │  │
    │  │ initialCampaign: Campaign          │  │
    │  └─────────────────────────────────────┘  │
    │                                           │
    │  Validation System:                       │
    │  ┌─────────────────────────────────────┐  │
    │  │ Field-by-field validation:          │  │
    │  │ • name (purpose)                    │  │
    │  │ • target (formatted target)         │  │
    │  │ • link (jar URL)                    │  │
    │  │ • image (image data)                │  │
    │  │ • template                          │  │
    │  └─────────────────────────────────────┘  │
    │                                           │
    │  Photo Management:                        │
    │  ┌─────────────────────────────────────┐  │
    │  │ PhotosPickerItem → Data conversion  │  │
    │  │ PHAuthorizationStatus checking      │  │
    │  │ Image rendering & library saving    │  │
    │  └─────────────────────────────────────┘  │
    │                                           │
    │  Delegate Actions:                        │
    │  • saveCampaign(Campaign) ↑              │
    │  • deleteCampaign(Campaign.ID) ↑         │
    └─────────────────┬─────────────────────────┘
                      │
    ┌─────────────────▼─────────────────────┐
    │        TemplateSelectionFeature       │
    │                                       │
    │  Template Management:                 │
    │  ┌─────────────────────────────────┐  │
    │  │ templates: IdentifiedArrayOf    │  │
    │  │ selectedTemplateID: Template.ID │  │
    │  │ campaign: Campaign (copy)       │  │
    │  └─────────────────────────────────┘  │
    │                                       │
    │  Image Positioning:                   │
    │  ┌─────────────────────────────────┐  │
    │  │ Interactive image manipulation: │  │
    │  │ • imageScale: CGFloat           │  │
    │  │ • imageOffset: CGSize           │  │
    │  │ • referenceSize: CGSize         │  │
    │  └─────────────────────────────────┘  │
    │                                       │
    │  Delegate Actions:                    │
    │  • templateApplied(template, id) ↑    │
    │  • imageRepositioned(scale, ...) ↑    │
    └───────────────────────────────────────┘

Data Flow Patterns:

1. INITIALIZATION FLOW:
   App Launch → AppFeature.init → CampaignsFeature.init 
   → JSON decode → Load campaigns → API calls for jar details

2. NAVIGATION FLOW:
   CampaignsView.campaignSelected → AppFeature.path.append(.details)
   → CampaignDetailsView → Template button → path.append(.templateSelection)

3. SAVE FLOW:
   Template/Details changes → Delegate actions → AppFeature updates
   → Auto-save debounce → JSON encode → File system write

4. VALIDATION FLOW:
   User input → @BindingState updates → validateForm() 
   → ValidationErrors → UI error display

5. IMAGE FLOW:
   PhotosPicker → Data conversion → Campaign.image update
   → Template application → Image positioning → Final render
```

### Key Components

**AppFeature**: Root feature managing the entire application state and navigation
- Handles the navigation stack using `StackState<Path.State>`
- Coordinates between different screens via delegate actions
- Implements auto-save with 1-second debounce using `continuousClock`
- Manages campaign updates from child features

**CampaignsFeature**: Main screen displaying the list of campaigns
- Loads campaigns from JSON on initialization with error handling
- Manages parallel API calls to fetch jar progress details
- Handles campaign creation and selection through presentation states
- Maintains `IdentifiedArrayOf<Campaign>` for efficient updates

**CampaignDetailsFeature**: Form for editing campaign details
- Complex validation system with field-specific error tracking
- Photo picker integration with permission handling
- Real-time form validation using `ValidationClient` dependency
- Manages campaign state changes and delegates saves/deletes upward

**TemplateSelectionFeature**: Interface for choosing promotional templates
- Template selection from predefined `Template.list`
- Interactive image positioning with scale and offset controls
- Real-time preview of template application
- Delegates template and positioning changes back to parent

### Data Persistence

- Campaign data is stored locally as JSON in the app's documents directory
- File location: `Documents/campaigns.json`
- Data is automatically saved using debounced effects (1-second delay)
- Loading happens during `CampaignsFeature` initialization with graceful error handling

### State Management

Each feature maintains its own state and communicates through actions:
- **Actions**: User interactions and system events (binding, delegate, presentation)
- **Reducers**: Pure functions that handle state transitions and coordinate between features
- **Effects**: Handle side effects like data persistence, API calls, and photo library operations
- **Dependencies**: Injected services for testability (DataManager, ValidationClient, JarApiClient, etc.)

This architecture ensures predictable state management, easy testing, and maintainable code structure.
