# All Icons Updated with New Logo Image

## Summary
All app icons, splash screens, and in-app images have been updated to use the Guitar-Pal logo image.

## Files Using the Logo

### 1. App Launcher Icons
**Configuration**: Uses `logo_padded.png` (padded version for full visibility)
- Android launcher icons (all densities)
- Android adaptive icons (foreground layer)
- iOS app icons (all sizes)

**File**: `mobile_app/assets/images/logo_padded.png`
- 2000 x 2000 pixels canvas
- 360px transparent padding on all sides
- Logo centered and fully visible

### 2. Native Splash Screen
**Configuration**: Uses original `logo-2287665_1280.png`
- Android splash screens (all densities)
- Android 12+ splash screens
- iOS splash screens

**File**: `mobile_app/assets/images/logo-2287665_1280.png`
- Displayed on dark background (#1a1a2e)
- Centered on screen
- Shows briefly before Flutter splash

### 3. Flutter Splash Screen (In-App)
**Location**: `lib/widgets/splash_screen.dart`
**File**: `mobile_app/assets/images/logo-2287665_1280.png`
- 200 x 200 display size
- Shown with "Guitar-Pal" text below
- Includes loading animation
- 3-second duration

### 4. Home Page Logo
**Location**: `lib/main.dart` - HomePage widget
**File**: `mobile_app/assets/images/logo-2287665_1280.png`
- 120 x 120 display size
- Shown on home screen
- Above welcome message

## Image Files in Assets

### Primary Logo
`mobile_app/assets/images/logo-2287665_1280.png`
- Original logo image
- Used for: splash screens, in-app display
- Size: 1280 x 1088 pixels (guitar pick shape)

### Padded Logo (for Icons)
`mobile_app/assets/images/logo_padded.png`
- Auto-generated with transparent padding
- Used for: launcher icons only
- Size: 2000 x 2000 pixels
- Content: Original logo centered with 360px padding

### Backup
`mobile_app/assets/images/logo-2287665_1280_backup.png`
- Backup of previous logo (if different)

## Generated Icon Files

### Android
- `android/app/src/main/res/mipmap-*/ic_launcher.png` (all densities)
- `android/app/src/main/res/drawable-*/ic_launcher_foreground.png` (adaptive icon foreground)
- `android/app/src/main/res/drawable-*/splash.png` (splash screen images)
- `android/app/src/main/res/drawable-*-v31/android12splash.png` (Android 12+ splash)

### iOS
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` (all icon sizes)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/*` (splash images)

## Commands Run

### Icons Generation
```bash
flutter pub run flutter_launcher_icons
```
Generates all launcher icons using `logo_padded.png`

### Splash Screens Generation
```bash
flutter pub run flutter_native_splash:create
```
Generates all splash screens using `logo-2287665_1280.png`

### Padding Script
```bash
python add_padding_to_logo.py
```
Creates `logo_padded.png` from `logo-2287665_1280.png`

## Configuration Files

### pubspec.yaml - Icons
```yaml
flutter_launcher_icons:
  image_path: "assets/images/logo_padded.png"
  adaptive_icon_foreground: "assets/images/logo_padded.png"
  adaptive_icon_background: "#FFFFFF"
```

### pubspec.yaml - Splash
```yaml
flutter_native_splash:
  image: "assets/images/logo-2287665_1280.png"
  image_dark: "assets/images/logo-2287665_1280.png"
  color: "#1a1a2e"
  android_12:
    image: "assets/images/logo-2287665_1280.png"
```

## To Update Logo in Future

If you need to replace the logo with a new image:

1. **Replace the source file**:
   - Save new image as `mobile_app/assets/images/logo-2287665_1280.png`

2. **Regenerate padded version**:
   ```bash
   python add_padding_to_logo.py
   ```

3. **Regenerate icons**:
   ```bash
   cd mobile_app
   flutter pub run flutter_launcher_icons
   ```

4. **Regenerate splash screens**:
   ```bash
   flutter pub run flutter_native_splash:create
   ```

5. **Test**:
   - Uninstall app completely
   - Run `flutter clean`
   - Run `flutter run`

## Current Status

✅ **App Launcher Icon**: Using `logo_padded.png` with 360px padding
- Full logo visible
- White background
- All edges visible

✅ **Native Splash Screen**: Using `logo-2287665_1280.png`
- Centered logo
- Dark background
- No branding at bottom

✅ **Flutter Splash Screen**: Using `logo-2287665_1280.png`
- Logo + "Guitar-Pal" text
- Tagline
- Loading animation

✅ **Home Page**: Using `logo-2287665_1280.png`
- 120x120 size
- Above welcome message

## All images are now using the Guitar-Pal logo! 🎸✨
