# Integration Instructions for New Files

This document describes the new files added to the Feather project and how to integrate them into the Xcode project.

## New Files Added

### Tab Bar Customization
- `Feather/Views/Settings/Appearance/TabBarCustomizationView.swift` - New settings view for customizing which tabs are visible

### Enhanced Files Tab
- `Feather/Views/Files/CreatePlistView.swift` - View for creating new plist files with format selection
- `Feather/Views/Files/DocumentPickerView.swift` - UIKit wrapper for importing any file type
- `Feather/Views/Files/FileInfoView.swift` - Detailed file information display
- `Feather/Views/Files/ShareSheet.swift` - UIKit wrapper for sharing files
- `Feather/Views/Files/ZipOperationView.swift` - Complete zip/unzip functionality with progress

## Modified Files
- `Feather/Views/TabView/TabEnum.swift` - Updated tab structure (removed certificates from customizable, added files/guides to default)
- `Feather/Views/TabView/Bars/TabbarView.swift` - Updated to respect tab visibility settings
- `Feather/Views/TabView/Bars/ExtendedTabbarView.swift` - Updated to respect tab visibility settings
- `Feather/Views/Settings/Appearance/AppearanceView.swift` - Added Tab Bar section
- `Feather/Views/Settings/SettingsView.swift` - Removed FilesTabSettingsView link (replaced by TabBarCustomizationView)
- `Feather/Views/Files/FilesView.swift` - Completely enhanced with all required features
- `Feather/Views/Files/PlistEditorView.swift` - Enhanced with validation, format conversion, and better editing

## Xcode Project Integration

**IMPORTANT**: The new Swift files need to be added to the Xcode project. Since this was done via automated tools, you'll need to either:

1. **Open the project in Xcode and manually add the files**:
   - Right-click on the `Feather/Views/Settings/Appearance` folder
   - Select "Add Files to Feather..."
   - Add `TabBarCustomizationView.swift`
   - Repeat for files in `Feather/Views/Files`:
     - `CreatePlistView.swift`
     - `DocumentPickerView.swift`
     - `FileInfoView.swift`
     - `ShareSheet.swift`
     - `ZipOperationView.swift`
   - Ensure "Copy items if needed" is UNCHECKED (files are already in place)
   - Ensure "Create groups" is selected
   - Ensure the Feather target is checked

2. **Or use xcodegen** (if available):
   - Update project.yml to include the new files
   - Run `xcodegen generate`

## Features Implemented

### Tab Bar Configuration
✅ Certificates removed from customizable tabs
✅ Files and Guides moved to default tabs (always visible by default)
✅ Tab Bar Customization settings in Appearance
✅ User can show/hide individual tabs (except Settings)
✅ Minimum 2 tabs enforced (Settings + at least 1 other)
✅ Settings cannot be hidden

### Files Tab - Core Features
✅ Import any file type via UIDocumentPickerViewController
✅ Export single/multiple files via share sheet
✅ Files persist in app's Documents/FeatherFiles directory
✅ Grid and list layout views
✅ Search files by name
✅ Sort by name, date, size, type
✅ Multi-selection mode for batch operations

### Files Tab - File Operations
✅ Create text files
✅ Create folders with custom SF Symbol icons
✅ Create plist files (XML or Binary format)
✅ Rename files with extension validation
✅ Duplicate files
✅ Delete files (swipe or batch)
✅ File info inspector (size, path, type, dates)
✅ Navigate folder hierarchy

### Files Tab - Zip Support
✅ Create zip archives from selected files/folders
✅ Unzip archives
✅ Progress indicators for large operations
✅ Conflict resolution (rename/replace/skip)
✅ Integrated with existing Zip library

### Files Tab - Plist Editor
✅ Create new plist files with format selection
✅ Edit plist files as XML text
✅ Validate plist structure before saving
✅ Convert between XML and Binary formats
✅ Format XML output
✅ Show validation errors
✅ Block saving invalid plists

### Edge Cases Handled
✅ File operations persist across app restarts
✅ Name conflict resolution on import
✅ Duplicate file name handling
✅ Directory navigation within app sandbox
✅ Empty state with helpful UI
✅ Error messages with HapticsManager feedback
✅ AppLogManager integration for debugging

## Testing Checklist

When the project builds successfully, test the following:

### Tab Bar
- [ ] Open Appearance settings → Tab Bar Customization
- [ ] Toggle tabs on/off (verify Settings cannot be disabled)
- [ ] Verify minimum 2 tabs is enforced
- [ ] Restart app and verify tab visibility persists
- [ ] Verify Files and Guides tabs are in main tab bar (not "More")

### Files Tab - Import/Export
- [ ] Import a .txt file
- [ ] Import a .zip file
- [ ] Import a .plist file
- [ ] Import a .json, .xml, .ipa file
- [ ] Export a single file via share sheet
- [ ] Select multiple files and export via share sheet

### Files Tab - File Management
- [ ] Create a text file
- [ ] Create a folder
- [ ] Create a plist file (XML and Binary)
- [ ] Rename a file
- [ ] Duplicate a file
- [ ] Delete files via swipe
- [ ] Delete multiple files in selection mode
- [ ] View file info
- [ ] Navigate into and out of folders
- [ ] Search for files
- [ ] Sort by different criteria
- [ ] Switch between list and grid view

### Files Tab - Zip Operations
- [ ] Select multiple files and create a zip
- [ ] Create a zip of a folder
- [ ] Unzip a file
- [ ] Test progress indicator with large files
- [ ] Test conflict resolution options

### Files Tab - Plist Editor
- [ ] Create a new XML plist
- [ ] Create a new Binary plist
- [ ] Edit a plist file
- [ ] Try to save invalid plist (should be blocked)
- [ ] Validate plist structure
- [ ] Convert XML plist to Binary
- [ ] Convert Binary plist to XML
- [ ] Format an XML plist

### Persistence
- [ ] Create files, close app, reopen - verify files are still there
- [ ] Import files, close app, reopen - verify files persist
- [ ] Customize tabs, close app, reopen - verify settings persist

## Known Issues / Notes

1. The new Swift files need to be added to the Xcode project file (project.pbxproj). This should be done through Xcode's UI as described above.

2. The app requires the `Zip` library which appears to already be integrated via the existing `import Zip` statements in the codebase.

3. Some UI strings use `.localized()` which assumes a localization system is in place. If strings don't appear correctly, check the localization setup.

4. The file manager operates within the app's sandbox at `Documents/FeatherFiles` for security.

5. UIDocumentPickerViewController requires appropriate Info.plist keys for file access (these should already be configured if the app works with files).

## Future Enhancements

Potential improvements that could be added later:
- Structured plist editor with key-value tree view
- File preview with Quick Look
- Drag and drop between folders
- Cloud sync support
- More file type editors (JSON, XML, etc.)
- Advanced search filters
- File tagging system
