# Individual Recipe

A personal offline recipe manager built with Flutter. 📱 Create, search, and track your recipes with full control over your data.

## Features

- **Offline-First**: All data stored locally (SQLite on mobile, LocalStorage on web)
- **Recipe Management**: Create, edit, delete recipes with detailed information (ingredients, steps, timing, cuisine, cooking methods)
- **Smart Search**: Search by name, ingredients, tags, categories, and cooking methods
- **Cooking Mode**: Step-by-step cooking guide with screen wake lock to keep display on
- **Cooking History**: Track cooking logs and see your most-cooked recipes
- **Favorites & Reviews**: Star your favorite recipes and leave reviews with ratings
- **Ingredient Aliases**: Map ingredient names (e.g., "salt" / "소금") for better search results
- **Recipe Packs**: Import pre-made recipe collections
- **Backup & Restore**: Export/import recipes as JSON files
- **Responsive Design**: Works on Android, iOS, macOS, Windows, Linux, and Web
- **Customizable Appearance**: Choose from 3 color palettes (Warm Brown, Cool Blue, Teal Green) + Dark Mode support
- **Google Fonts**: Beautiful typography with Inter font family

## Current direction

- App name: Individual Recipe
- Flutter package name: individual_recipe
- Storage model: offline-first local storage
- Web storage: LocalStorage for the current test build
- Mobile storage: SQLite via sqflite
- Firebase: intentionally removed
- Future hosting target: Cloudflare Pages for the Flutter web build

## Version 1.2.0 (Design & Theme Update)

- **Multiple Color Palettes**: Choose from Warm Brown (A), Cool Blue (B), or Teal Green (C)
- **Dark Mode Support**: Light and Dark theme modes with full color palette support
- **Google Fonts Integration**: Improved typography with Inter font family
- **Enhanced UI Design**: Improved spacing, card designs, and visual consistency
- **Settings Panel**: Easy theme customization from Settings screen

## Version 1.1.0 (Previous release)

- Firebase dependencies removed from the Flutter project.
- App identity renamed to Individual Recipe across Flutter, Web, Android, iOS, macOS, Windows, and Linux metadata where applicable.
- Search/category logic moved into `lib/services/recipe_filter_service.dart`.
- Category chip counts are calculated from the full searched set, not from the currently selected tab.
- Recipe Provider now loads the full recipe list once and derives drafts/favorites/recent/top-cooked in memory.
- Cooking mode no longer crashes when a recipe has no steps.
- Reviews are now persisted in Web LocalStorage and Mobile SQLite, and included in JSON backup/restore.
- Web LocalStorage migrates legacy `recipe_keeper` keys to the new `individual_recipe` keys when possible.
- Mobile SQLite schema upgraded to version 5 with indexes and structured recipe clarity fields.
- Export/import/reset now cover recipes, aliases, cooking logs, and reviews.
- Recipes now support clearer structure: description, cuisine, cooking methods, prep time, cook time, and servings.
- Existing recipe packs automatically infer cuisine and cooking methods from categories, tags, steps, and notes.

## Why Firebase was removed

This app is not using Firebase Auth, Firestore, Firebase Storage, or Firebase Hosting.
Keeping Firebase dependencies in the project adds package weight and creates unnecessary setup/configuration risk.

If cloud sync is needed later, the recommended direction is not Firebase by default. For Cloudflare deployment, consider:

- Cloudflare Pages for static Flutter web hosting
- Cloudflare Workers for API endpoints
- Cloudflare D1 for structured relational data
- Cloudflare R2 for recipe images/backups if needed
- Cloudflare Access or custom auth later if accounts are required

## Installation & Setup

### Requirements

- Flutter SDK 3.9.2 or later
- Dart 3.9.2 or later

### Getting Started

1. Clone the repository:
```bash
git clone https://github.com/yourusername/individual-recipe.git
cd individual-recipe
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# On mobile/tablet
flutter run

# On web (Chrome)
flutter run -d chrome

# On desktop (macOS/Linux/Windows)
flutter run -d macos    # or 'linux' or 'windows'
```

## Development

### Code quality checks
```bash
flutter analyze      # Run static analysis
flutter test        # Run unit tests (if available)
```

### Clean build
```bash
flutter clean
rm -f pubspec.lock
flutter pub get
flutter run
```

## Building for Web (Cloudflare Pages)

To build the web version:

```bash
flutter build web --release
```

Deploy to Cloudflare Pages:

1. Upload `build/web` directory to Cloudflare Pages
2. Cloudflare Pages settings:
   - Build command: `flutter build web --release`
   - Output directory: `build/web`

Alternatively, build locally and upload `build/web` directly if Cloudflare build environment has issues.

## Architecture

### Storage

- **Mobile/Desktop**: SQLite via `sqflite` (SQLite v5 schema with indexes)
- **Web**: LocalStorage (suitable for testing, consider R2 for production)

### State Management

- **Provider 6.x**: For recipe data, aliases, and cooking state
- **SharedPreferences**: For user preferences (theme, color palette)

### Key Components

- `lib/screens/`: Main UI screens (Home, Search, Recipes, Cooking, Settings, etc.)
- `lib/providers/`: State management (RecipeProvider, AliasProvider)
- `lib/services/`: Business logic (RecipeFilterService for search/filter/sort)
- `lib/models/`: Data classes (Recipe, RecipeHistory, Review, etc.)
- `lib/database/`: Database layer with platform-specific implementations
- `lib/widgets/`: Reusable UI components

## Future Enhancements

- Cross-device sync via Cloudflare Workers + D1
- Ingredient statistics and nutrition tracking
- Shopping list feature
- Advanced recipe filtering and sorting options
- Recipe images stored on Cloudflare R2
- User accounts and cloud backup (optional)
