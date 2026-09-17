# GC5 Jersey Studio & Converter

## Project Type

Flutter Android utility app for Game Changer 5 (GC5) cricket game modders.

## Main Goal

Build a 2-in-1 utility app that allows users to:

1. Select a custom 2D cricket jersey PNG.
2. Preview that jersey texture on a 3D cricket player model.
3. Rotate and zoom the 3D player.
4. Capture a branded showcase screenshot.
5. Save the screenshot to the gallery.
6. Share the screenshot through Android's share sheet.
7. Convert one or multiple PNG files into `.bytes` files.
8. Save converted files using Android storage/file picker mechanisms.
9. Add reasonable app protection against simple repackaging and reverse engineering.

---

# IMPORTANT DEVELOPMENT RULES FOR AI AGENT

## Rule 1 - Work Phase by Phase

Do NOT build the entire application at once.

The project must be developed in separate phases.

Complete one phase first, test it, fix issues, and only then move to the next phase.

Do not start a future phase until the current phase is working.

---

## Rule 2 - Beginner-Friendly Code

Keep the Flutter architecture understandable.

Avoid unnecessary:

- Clean Architecture
- Repository patterns
- Dependency injection frameworks
- complicated state-management architecture
- excessive abstractions
- unnecessary classes
- unnecessary files

Use simple and readable Flutter code.

If a feature can be implemented cleanly with normal Flutter widgets and a small service class, prefer that.

---

## Rule 3 - Explain Before Major Changes

Before implementing a major feature, briefly explain:

- what we are building
- why it is needed
- which package/technology is being used
- which files will change

Then implement it.

Do not dump hundreds of lines of unexplained code.

---

## Rule 4 - Test After Every Phase

After completing each phase:

1. Run `flutter analyze`
2. Run the application
3. Test the implemented feature on Android
4. Fix errors
5. Confirm the phase is complete

Do not move forward with known errors.

---

# Final App Structure

The application should have two primary sections.

## Tab 1

### 3D Jersey Tester

User selects a PNG jersey texture.

The app displays the texture on a generic 3D cricket player model.

User can:

- rotate player
- zoom player
- inspect jersey
- capture showcase screenshot
- share screenshot

---

## Tab 2

### PNG → .bytes Converter

User selects:

- one PNG
- multiple PNG files

The app converts the PNG file's binary content into a `.bytes` file.

Example:

```text
jersey.png
       ↓
readAsBytes()
       ↓
Uint8List
       ↓
jersey.bytes
```

The actual binary data should remain unchanged.

---

# Suggested Project Structure

Keep the project simple.

```text
lib/
│
├── main.dart
│
├── app.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── jersey_tester_screen.dart
│   └── converter_screen.dart
│
├── widgets/
│   ├── app_bottom_navigation.dart
│   ├── texture_picker_button.dart
│   ├── model_viewer_widget.dart
│   ├── showcase_overlay.dart
│   └── empty_state.dart
│
├── services/
│   ├── texture_service.dart
│   ├── bytes_converter_service.dart
│   ├── screenshot_service.dart
│   ├── gallery_service.dart
│   └── integrity_service.dart
│
├── models/
│   └── selected_file.dart
│
├── utils/
│   ├── constants.dart
│   └── helpers.dart
│
└── theme/
    └── app_theme.dart
```

The structure can be changed if a package requires a different implementation, but unnecessary restructuring should be avoided.

---

# PHASE 0 - Project Setup & Feasibility

## Objective

Create the Flutter project and verify that the main technical requirements are possible before building the UI.

## Tasks

Create Flutter Android project with final package ID:

```text
com.yourdomain.gc5jerseystudio
```

Replace the placeholder with the final chosen package ID before release.

Set up:

- Flutter project
- Android configuration
- app name
- launcher icon placeholder
- basic theme
- required permissions only when actually needed

Add initial dependencies gradually.

Potential packages:

```text
model_viewer_plus
file_picker
path_provider
share_plus
package_info_plus
gal
screenshot
```

Do NOT add every package immediately if it is not yet needed.

## Important Technical Investigation

Before committing to the 3D implementation, test the selected 3D package with a small sample model.

The agent must verify:

- Can the model load on Android?
- Can it rotate?
- Can it zoom?
- Can a local or downloaded `.glb` model be displayed?
- Can its material/texture be changed dynamically?
- Can the selected PNG be applied to the model?

If `model_viewer_plus` cannot support the required runtime texture replacement reliably, investigate an alternative such as:

- `flutter_gl`
- Three.js based solution
- another maintained Flutter 3D renderer

Do not blindly continue with a package that cannot perform dynamic texture mapping.

## Deliverable

A basic Flutter app that launches successfully on Android.

---

# PHASE 1 - Basic UI / App Shell

## Objective

Build the complete basic navigation structure without implementing advanced functionality.

## UI

Create a modern dark gaming/modding style interface.

Suggested structure:

```text
┌─────────────────────────────┐
│ GC5 Jersey Studio           │
│                             │
│        App Content          │
│                             │
│                             │
│                             │
├─────────────────────────────┤
│  3D Tester  │   Converter  │
└─────────────────────────────┘
```

## Tester Screen

Create:

- app title
- empty 3D viewer placeholder
- "Select Jersey PNG" button
- screenshot button placeholder
- basic instructions

Example empty state:

```text
Select a GC5 jersey PNG
to preview it on the player.
```

## Converter Screen

Create:

- file selection button
- selected file list
- convert button
- output status area

## Deliverable

Navigation between both tabs works correctly.

No real 3D or conversion functionality yet.

---

# PHASE 2 - PNG File Selection

## Objective

Allow users to select jersey PNG files from Android storage.

## Package

Use:

```text
file_picker
```

## Requirements

Tester:

- Select one PNG file.
- Restrict picker to image/PNG where possible.
- Display selected filename.
- Display selected image preview.

Converter:

- Support one or multiple PNG files.
- Display selected filenames.
- Allow removing individual files.
- Allow clearing all selected files.

## Example

```text
Selected Files

✓ pakistan_2026.png
✓ india_2026.png
✓ australia_2026.png

[ Convert to .bytes ]
```

## Validation

Reject:

- non-PNG files
- unavailable files
- invalid selections

Show simple user-friendly error messages.

## Deliverable

Reliable PNG selection system.

---

# PHASE 3 - 3D Player Viewer

## Objective

Implement the actual 3D cricket player.

## Requirements

Use a generic cricket player `.glb` model.

The model should have:

- full player body
- cricket clothing
- proper UV mapping
- jersey material
- reasonable polygon count for mobile
- reasonable texture resolution

The model should work well on Android devices.

## Controls

User must be able to:

- rotate horizontally
- rotate vertically where supported
- zoom in
- zoom out
- reset view

The viewer should not feel unnecessarily complicated.

## UI

Example:

```text
┌─────────────────────────────┐
│                             │
│        3D PLAYER            │
│                             │
│                             │
│                             │
│        [ Reset ]            │
└─────────────────────────────┘

[ Select Jersey PNG ]
```

## Performance

Optimize for mobile.

Avoid unnecessarily huge:

- GLB files
- textures
- polygon counts

Test on a physical Android device.

---

# PHASE 4 - Dynamic Jersey Texture Mapping

## Objective

This is one of the most important phases.

The selected PNG must appear on the 3D player's jersey.

## Process

```text
PNG selected
     ↓
Read image
     ↓
Load texture
     ↓
Apply texture to correct material
     ↓
3D player updates
```

## Critical Requirement

The 3D model's UV map must match the expected GC5 jersey texture layout.

The agent must NOT assume that any random cricket model will work.

The model needs a compatible UV layout.

## Testing

Test multiple textures:

```text
jersey1.png
jersey2.png
jersey3.png
```

Verify:

- front appears correctly
- back appears correctly
- sleeves appear correctly
- logos/graphics remain aligned
- texture does not appear upside down
- texture does not stretch unexpectedly

## Important

If the selected 3D library cannot dynamically replace the texture at runtime, stop and evaluate another rendering approach.

Do not fake this feature using a static model screenshot.

## Deliverable

A user-selected PNG visibly changes the jersey on the 3D player.

---

# PHASE 5 - 3D Viewer Branding / Watermark

## Objective

Add subtle branding to the preview.

The watermark should be visible while the model is being viewed.

Example:

```text
GC5 Jersey Studio
```

or:

```text
Created with GC5 Jersey Studio
```

## Requirements

The watermark should:

- be subtle
- not block the jersey
- remain visible during normal viewing
- look good on different backgrounds

Possible placement:

```text
bottom-right
```

or

```text
bottom-center
```

## Important

The watermark should be part of the captured showcase composition too.

---

# PHASE 6 - Showcase Screenshot System

## Objective

Create a polished screenshot feature for community sharing.

## User Flow

```text
User selects jersey
       ↓
3D preview
       ↓
rotate / zoom
       ↓
Tap "Take Showcase"
       ↓
Capture preview
       ↓
Add branding overlay
       ↓
Save to gallery
       ↓
Open Android share sheet
```

## Screenshot UI

Add button:

```text
📸 Take Showcase
```

or:

```text
Take Screenshot & Share
```

## Showcase Design

The generated image should include:

- 3D player preview
- jersey
- subtle border/frame
- app name
- watermark
- optional "GC5 Jersey Studio"
- optional small text such as "Custom Jersey Preview"

Do not make the branding so large that it ruins the showcase.

## Screenshot Quality

Capture the highest practical resolution supported by the implementation.

Avoid capturing unnecessary parts of the app UI.

The showcase image should look intentional, not like a random screenshot of the entire phone screen.

---

# PHASE 7 - Save Screenshot to Gallery

## Objective

Save generated showcase images to Android gallery.

Potential package:

```text
gal
```

or an appropriate maintained gallery/media-saving solution.

## Requirements

After screenshot:

```text
Showcase generated successfully
```

Then save it.

Suggested filename:

```text
GC5_Jersey_Studio_2026-09-14_221530.jpg
```

or PNG if transparency/quality requires it.

## Permissions

Request Android permissions only when necessary.

The permission flow should be user-friendly.

Do not request all storage permissions at application startup.

## Error Handling

Handle:

- permission denied
- gallery save failure
- invalid screenshot
- storage problems

---

# PHASE 8 - Android Share Sheet

## Objective

Allow users to share the generated showcase.

## Package

Use:

```text
share_plus
```

## Flow

```text
Screenshot generated
       ↓
Saved
       ↓
Share
       ↓
Android native share sheet
```

The user can then choose apps such as:

- WhatsApp
- Telegram
- Facebook
- Messenger
- Gmail
- etc.

Do not build separate integrations for each social media app.

Use Android's native sharing mechanism.

## Deliverable

One button should make the showcase ready for sharing.

---

# PHASE 9 - PNG → .bytes Converter

## Objective

Build the second major feature.

## Core Logic

The conversion is intentionally simple.

Example:

```dart
final bytes = await File(inputPath).readAsBytes();
```

Then write exactly those bytes into a file ending in `.bytes`.

Example:

```text
Pakistan_Jersey.png
        ↓
Pakistan_Jersey.bytes
```

## IMPORTANT

Do NOT:

- resize image
- compress image
- convert PNG to another image format
- decode and re-encode the PNG
- modify the binary content

The `.bytes` output must contain the same binary data as the source PNG unless GC5's actual format specification later proves that additional transformation is required.

## Verification

For every conversion:

```text
Input file size
Output file size
```

should normally match.

Example:

```text
Input:
jersey.png
Size: 245 KB

Output:
jersey.bytes
Size: 245 KB
```

The agent should optionally verify byte-for-byte equality during development/testing.

---

# PHASE 10 - Multiple File Conversion

## Objective

Support batch conversion.

Example:

```text
Selected Files

✓ Pakistan.png
✓ India.png
✓ England.png
✓ Australia.png

[ Convert All ]
```

Output:

```text
Pakistan.bytes
India.bytes
England.bytes
Australia.bytes
```

## Requirements

Show progress for multiple files.

Example:

```text
Converting...

3 / 10
```

After completion:

```text
10 files converted successfully
```

If some fail:

```text
8 converted successfully
2 failed
```

Provide enough information for the user to understand which files failed.

---

# PHASE 11 - Export / Storage Access

## Objective

Allow the user to choose where `.bytes` files should be saved.

The implementation must follow modern Android storage rules.

## Preferred Flow

Use Android's file/folder picker or Storage Access Framework where appropriate.

Example:

```text
Convert
   ↓
Choose Output Folder
   ↓
Save .bytes files
```

## Requirements

Do not depend on unrestricted access to:

```text
/storage/emulated/0/
```

unless Android version and permissions genuinely support it.

Avoid old storage hacks.

## User Experience

Example:

```text
Output Folder

/Download/GC5 Jersey Studio/

[ Choose Folder ]

[ Convert & Save ]
```

If persistent folder access is technically possible and reliable, support it.

Otherwise ask the user to select the output location when required.

---

# PHASE 12 - File Management UI

## Objective

Make the converter feel like a proper utility instead of a raw file picker.

## Features

Show:

- filename
- file size
- PNG status
- selected/unselected state
- remove button

Example:

```text
┌──────────────────────────────┐
│ Pakistan Jersey.png          │
│ 245 KB                       │
│                        [ X ] │
└──────────────────────────────┘
```

Add:

```text
Clear All
```

and:

```text
Convert All
```

---

# PHASE 13 - Error Handling

## Objective

Handle real-world problems properly.

The app should gracefully handle:

### File Problems

- file does not exist
- corrupted file
- unsupported format
- permission denied
- inaccessible URI

### 3D Problems

- model failed to load
- texture failed to load
- unsupported texture
- rendering failure

### Storage Problems

- unable to save
- folder unavailable
- insufficient storage

### Sharing Problems

- screenshot unavailable
- share operation failed

Never crash the entire application because of a single file.

Use simple messages such as:

```text
Unable to load this jersey.
Please select a valid PNG file.
```

---

# PHASE 14 - Runtime Package Integrity Check

## Objective

Add a basic protection layer against simple repackaging/cloning.

## Package

Use:

```text
package_info_plus
```

## Concept

At startup:

```text
Read actual package name
        ↓
Compare with expected package name
        ↓
Match?
  ↓ yes
Continue
  ↓ no
Show error / terminate
```

Expected package ID should be stored as a release configuration value rather than scattered throughout the project.

Example:

```text
com.yourdomain.gc5jerseystudio
```

## Important Security Note

This is NOT a perfect anti-cloning mechanism.

A determined attacker can patch the APK and bypass a client-side package check.

Therefore this should be treated as one protection layer only.

Do not claim:

```text
Impossible to clone
```

or:

```text
100% protected
```

---

# PHASE 15 - Flutter Release Obfuscation

## Objective

Make reverse engineering somewhat harder.

Build release APK/AAB using:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

For Play Store:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

## Important

Keep the generated debug-symbol information private.

Do not upload or publish the symbol files with the source code.

## Understand the Limitation

Flutter obfuscation makes code harder to understand.

It does NOT make the app impossible to reverse engineer.

---

# PHASE 16 - 3D Asset Hosting

## Objective

Avoid unnecessarily bundling the main 3D model directly inside the APK.

Possible hosting:

- Firebase Storage
- Firebase Hosting
- Cloud CDN
- another reliable HTTPS server

## Flow

```text
App starts
     ↓
Check model availability
     ↓
Download model
     ↓
Cache locally
     ↓
Load model
```

## Requirements

Use HTTPS.

Do not expose unnecessary Firebase credentials or secrets in the app.

## Important Security Reality

Remote hosting does NOT make the model impossible to extract.

If the Android application can download the model, a determined user can potentially obtain it.

Remote hosting mainly provides:

- easier model updates
- smaller initial APK/AAB
- ability to change the model without releasing a new app
- some additional friction against casual extraction

Do not describe this as complete asset protection.

---

# PHASE 17 - 3D Asset Caching

## Objective

Avoid downloading the model every time.

Flow:

```text
First launch
    ↓
Download model
    ↓
Cache locally
    ↓
Next launch
    ↓
Use cached model
```

If the remote model version changes:

```text
New version available
       ↓
Download new model
       ↓
Replace cache
```

Keep this system simple.

Do not build a complicated update framework unless necessary.

---

# PHASE 18 - Remote Configuration

## Objective

Allow basic configuration without publishing a new APK.

Potential configuration:

```json
{
  "modelUrl": "...",
  "modelVersion": "1.0",
  "watermarkText": "Created with GC5 Jersey Studio",
  "minimumAppVersion": "1.0.0"
}
```

Possible backend:

- Firebase Remote Config
- simple secure JSON endpoint

## Use Cases

Change:

- model URL
- model version
- watermark text
- maintenance mode
- minimum supported app version

Do not store secret credentials in this configuration.

---

# PHASE 19 - UI Polish

## Objective

Make the application look like a real published utility.

## Design

Use a consistent:

- dark theme
- typography
- spacing
- button style
- card style
- icon style

## Tester Screen

Possible layout:

```text
GC5 Jersey Studio

┌─────────────────────────────┐
│                             │
│                             │
│        3D PLAYER            │
│                             │
│                             │
│                    ↻ Reset  │
└─────────────────────────────┘

Pakistan Jersey.png

[ Change Jersey ]

[ 📸 Take Showcase ]
```

## Converter

```text
PNG → .BYTES

[ + Select PNG Files ]

Selected Files
──────────────

Pakistan.png
India.png
Australia.png

[ Clear All ]

Output Folder
/Download/GC5/

[ Convert Files ]
```

---

# PHASE 20 - Loading / Empty / Success States

Every important feature needs proper UI states.

## 3D Viewer

### Loading

```text
Loading Player...
```

### Model Error

```text
Unable to load the 3D player.
Try again.
```

### No Jersey

```text
Select a jersey PNG to begin.
```

### Texture Loading

```text
Applying Jersey...
```

---

## Converter

### No Files

```text
No PNG files selected.
```

### Converting

```text
Converting 4 files...
2 / 4
```

### Success

```text
4 files converted successfully.
```

### Partial Failure

```text
3 files converted.
1 file failed.
```

---

# PHASE 21 - Android Testing

Test on a real Android device.

Do NOT rely only on emulator testing.

## Test Cases

### Tester

- open app
- switch tabs
- select PNG
- display PNG preview
- load 3D model
- rotate model
- zoom model
- reset model
- apply texture
- change texture
- capture screenshot
- save screenshot
- share screenshot

### Converter

- select one PNG
- select multiple PNGs
- remove one
- clear all
- convert one
- convert multiple
- choose output folder
- save files
- verify file names
- verify file sizes
- verify binary contents

---

# PHASE 22 - Low-End Device Testing

The app is intended for mobile users, including users with lower-end Android devices.

Test:

- slow device
- limited RAM
- slow storage
- slow internet
- offline after model is cached

Check:

- FPS
- loading time
- memory usage
- crashes
- texture loading
- model loading

The app should not freeze because a large texture is selected.

---

# PHASE 23 - Texture Validation & Limits

Add reasonable limits to prevent crashes.

For example:

- maximum supported texture resolution
- maximum file size
- valid PNG validation

If an extremely large PNG is selected:

```text
This texture is too large.

Please use a smaller PNG texture.
```

The exact limits should be determined after testing.

Do not choose arbitrary limits before checking real GC5 textures.

---

# PHASE 24 - Final Security Review

Review:

### Application

- release build
- obfuscation
- package integrity check
- no debug logs containing sensitive information
- no test URLs
- no development credentials
- no Firebase secrets in source
- HTTPS only

### Remote Assets

- HTTPS
- versioning
- caching
- basic access controls if useful

### Storage

- no unnecessary broad storage permissions
- modern Android storage APIs

---

# PHASE 25 - Release Preparation

## App Information

Finalize:

```text
App Name:
GC5 Jersey Studio & Converter
```

Finalize:

- package ID
- version
- launcher icon
- splash screen
- privacy policy if required
- app description
- screenshots
- feature graphic
- Play Store declarations

## Release Build

Run:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

Then:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

Test the release AAB/APK before publishing.

---

# PHASE 26 - Final QA Checklist

## 3D Jersey Tester

- [ ] App launches
- [ ] Model loads
- [ ] Model rotates
- [ ] Model zooms
- [ ] Reset works
- [ ] PNG picker works
- [ ] PNG validation works
- [ ] Texture applies correctly
- [ ] Texture alignment is correct
- [ ] Multiple jersey textures can be tested
- [ ] Watermark visible
- [ ] Showcase button works
- [ ] Screenshot quality is good
- [ ] Screenshot saves to gallery
- [ ] Screenshot sharing works

## Converter

- [ ] Single PNG selection works
- [ ] Multiple PNG selection works
- [ ] Files can be removed
- [ ] Clear all works
- [ ] PNG validation works
- [ ] Conversion works
- [ ] `.bytes` extension is correct
- [ ] Binary contents remain unchanged
- [ ] Output folder selection works
- [ ] Files save correctly
- [ ] Duplicate filename handling works
- [ ] Error handling works

## Security

- [ ] Correct package ID
- [ ] Runtime package check
- [ ] Release obfuscation
- [ ] Split debug information
- [ ] No secrets in source
- [ ] HTTPS remote model
- [ ] Model caching works
- [ ] No unnecessary permissions

---

# PHASE ORDER

The AI agent MUST follow this exact general order:

```text
PHASE 0
Project Setup & 3D Feasibility
        ↓
PHASE 1
Basic UI
        ↓
PHASE 2
PNG File Selection
        ↓
PHASE 3
3D Player Viewer
        ↓
PHASE 4
Dynamic Texture Mapping
        ↓
PHASE 5
Watermark
        ↓
PHASE 6
Showcase Screenshot
        ↓
PHASE 7
Gallery Saving
        ↓
PHASE 8
Sharing
        ↓
PHASE 9
PNG → .bytes
        ↓
PHASE 10
Multiple Conversion
        ↓
PHASE 11
Storage / SAF
        ↓
PHASE 12
File Management UI
        ↓
PHASE 13
Error Handling
        ↓
PHASE 14
Package Integrity
        ↓
PHASE 15
Release Obfuscation
        ↓
PHASE 16
Remote 3D Hosting
        ↓
PHASE 17
3D Caching
        ↓
PHASE 18
Remote Configuration
        ↓
PHASE 19
UI Polish
        ↓
PHASE 20
Loading / Empty States
        ↓
PHASE 21
Android Testing
        ↓
PHASE 22
Low-End Testing
        ↓
PHASE 23
Texture Validation
        ↓
PHASE 24
Security Review
        ↓
PHASE 25
Release Preparation
        ↓
PHASE 26
Final QA
```

---

# IMPORTANT AGENT INSTRUCTION

Do not generate the whole application in one response.

At the beginning of development, start ONLY with:

```text
PHASE 0
```

After Phase 0 is successfully tested, proceed to Phase 1.

For every phase, report:

```text
PHASE:
What was implemented:

Files changed:

Packages added:

Testing performed:

Problems found:

Problems fixed:

Status:
PASS / NEEDS FIX
```

If a technical requirement is impossible with the selected package, do not create a fake implementation.

Explain the limitation and investigate a technically suitable alternative.

The final application must contain real functionality, not placeholder buttons pretending to perform the feature.

---

# FIRST AGENT COMMAND

Start development with Phase 0 only.

Your first job is to:

1. Inspect the existing Flutter project.
2. Verify Flutter/Android configuration.
3. Confirm the final package/application ID.
4. Add only the dependencies needed for Phase 0.
5. Create a minimal Flutter application.
6. Test a sample `.glb` cricket player model.
7. Determine whether the selected 3D package supports:
   - Android
   - model loading
   - rotation
   - zoom
   - dynamic texture replacement
8. Do not implement the converter, screenshot system, security system, or remote hosting yet.
9. Report the result of Phase 0.
10. Wait for approval before starting Phase 1.