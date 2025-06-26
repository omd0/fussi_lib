# 🚀 Release Process Guide - Fussi Library

## 📋 **Complete Release Checklist Template**

Use this guide every time you want to create a new release for Fussi Library.

---

## 🔧 **Step 1: Pre-Release Preparation**

### 1.1 Check Current Status
```bash
# Check git status
git status

# Check current version
grep "version:" pubspec.yaml

# Check existing releases
ls -la release/
```

### 1.2 Determine Next Version
- **Patch Release** (x.x.X): Bug fixes, small improvements
- **Minor Release** (x.X.x): New features, UI improvements
- **Major Release** (X.x.x): Breaking changes, major overhauls

**Version Format**: `MAJOR.MINOR.PATCH+BUILD`
- Example: `1.1.1+4` → `1.1.2+5` (patch)
- Example: `1.1.2+5` → `1.2.0+6` (minor)
- Example: `1.2.0+6` → `2.0.0+7` (major)

---

## 📝 **Step 2: Update Version Number**

### 2.1 Update pubspec.yaml
```bash
# Edit pubspec.yaml
# Change: version: 1.1.1+4
# To:     version: 1.1.2+5  (example)
```

**Template for version update**:
```yaml
version: [NEW_VERSION]+[NEW_BUILD_NUMBER]
```

---

## 📋 **Step 3: Create Release Notes**

### 3.1 Create Release Notes File
```bash
# Create new release notes file
touch release/RELEASE_NOTES_v[VERSION].md
```

### 3.2 Release Notes Template
```markdown
# 📚 Fussi Library v[VERSION] Release Notes

## 🎯 **[RELEASE_TYPE] Release**

### ✅ **Key Changes**
- **[CHANGE_TYPE]**: [DESCRIPTION]
- **[CHANGE_TYPE]**: [DESCRIPTION]

### 🔧 **Technical Improvements**
- **[IMPROVEMENT]**: [DESCRIPTION]
- **[IMPROVEMENT]**: [DESCRIPTION]

## 🎨 **User Interface Changes**

### 🧹 **UI Improvements**
- **[UI_CHANGE]**: [DESCRIPTION]
- **[UI_CHANGE]**: [DESCRIPTION]

## 🚀 **What's New**

### 📋 **New Features**
- [FEATURE]: [DESCRIPTION]
- [FEATURE]: [DESCRIPTION]

### 🔧 **Backend Improvements**
- [IMPROVEMENT]: [DESCRIPTION]
- [IMPROVEMENT]: [DESCRIPTION]

## 🐛 **Bug Fixes**

1. **[PRIORITY]**: [BUG_DESCRIPTION]
2. **[PRIORITY]**: [BUG_DESCRIPTION]

## 🔄 **Migration Notes**

- **[MIGRATION_ITEM]**: [DESCRIPTION]
- **[MIGRATION_ITEM]**: [DESCRIPTION]

## 📱 **Installation**

### Android APK
```bash
# Download and install the APK
wget https://github.com/omd0/fussi_lib/releases/download/v[VERSION]/fussi_library_v[VERSION].apk
adb install fussi_library_v[VERSION].apk
```

### Android Bundle (AAB)
- Available for Google Play Store distribution
- Optimized size and performance

## 🎯 **Key Improvements Summary**

| Area | Improvement | Impact |
|------|-------------|---------|
| **[AREA]** | [IMPROVEMENT] | 🟢 [PRIORITY] |
| **[AREA]** | [IMPROVEMENT] | 🟡 [PRIORITY] |

## 🔍 **Technical Details**

### [TECHNICAL_AREA]
- [DETAIL]: [DESCRIPTION]
- [DETAIL]: [DESCRIPTION]

## 📞 **Support**

For issues or questions:
- **GitHub Issues**: [Report bugs](https://github.com/omd0/fussi_lib/issues)
- **Documentation**: Check `/docs` folder for guides

---

**Version**: [VERSION]+[BUILD]  
**Release Date**: [DATE]  
**Compatibility**: Android 7.0+ (API 24+)  
**Size**: ~[SIZE]MB (APK), ~[SIZE]MB (AAB)
```

---

## 🏗️ **Step 4: Build Release Assets**

### 4.1 Build APK
```bash
# Build release APK
flutter build apk --release

# Check build result
ls -la build/app/outputs/flutter-apk/
```

### 4.2 Build AAB (Android App Bundle)
```bash
# Build release AAB
flutter build appbundle --release

# Check build result
ls -la build/app/outputs/bundle/release/
```

### 4.3 Copy to Release Directory
```bash
# Copy APK with proper naming
cp build/app/outputs/flutter-apk/app-release.apk release/fussi_library_v[VERSION].apk

# Copy AAB with proper naming
cp build/app/outputs/bundle/release/app-release.aab release/fussi_library_v[VERSION].aab

# Verify files
ls -la release/fussi_library_v[VERSION].*
```

---

## 📤 **Step 5: Commit and Push Changes**

### 5.1 Stage All Changes
```bash
# Add all changes
git add .

# Check what will be committed
git status
```

### 5.2 Commit with Descriptive Message
```bash
git commit -m "🚀 Release v[VERSION] - [RELEASE_TITLE]

📦 Version bump to [VERSION]+[BUILD]
📋 Added comprehensive release notes
📱 Built APK and AAB for distribution

Key changes:
- [CHANGE_1]
- [CHANGE_2]
- [CHANGE_3]"
```

### 5.3 Push to GitHub
```bash
# Push changes
git push origin main
```

---

## 🏷️ **Step 6: Create Git Tag**

### 6.1 Create Annotated Tag
```bash
git tag -a v[VERSION] -m "🚀 Release v[VERSION] - [RELEASE_TITLE]

🎯 [RELEASE_TYPE] Release:
- [KEY_CHANGE_1]
- [KEY_CHANGE_2]
- [KEY_CHANGE_3]

📱 Built for Android with APK and AAB distributions"
```

### 6.2 Push Tag
```bash
# Push tag to GitHub
git push origin v[VERSION]
```

---

## 🚀 **Step 7: Create GitHub Release**

### 7.1 Using GitHub CLI (Recommended)
```bash
# Create release with assets
gh release create v[VERSION] \
  --title "🚀 Fussi Library v[VERSION] - [RELEASE_TITLE]" \
  --notes-file release/RELEASE_NOTES_v[VERSION].md \
  release/fussi_library_v[VERSION].apk \
  release/fussi_library_v[VERSION].aab
```

### 7.2 Manual GitHub Release (Alternative)
1. Go to: https://github.com/omd0/fussi_lib/releases
2. Click "Create a new release"
3. Choose tag: `v[VERSION]`
4. Release title: `🚀 Fussi Library v[VERSION] - [RELEASE_TITLE]`
5. Description: Copy from `release/RELEASE_NOTES_v[VERSION].md`
6. Attach files:
   - `release/fussi_library_v[VERSION].apk`
   - `release/fussi_library_v[VERSION].aab`
7. Click "Publish release"

---

## 📋 **Step 8: Create Upload Ready Documentation**

### 8.1 Create Upload Ready File
```bash
touch release/UPLOAD_READY_v[VERSION].md
```

### 8.2 Upload Ready Template
```markdown
# 🚀 Fussi Library v[VERSION] - Upload Ready

## ✅ **Release Status: COMPLETED**

**Release URL**: https://github.com/omd0/fussi_lib/releases/tag/v[VERSION]

## 📦 **Release Assets**

### 📱 **Android Distributions**
- **APK**: `fussi_library_v[VERSION].apk` ([SIZE]MB)
- **AAB**: `fussi_library_v[VERSION].aab` ([SIZE]MB)

### 📋 **Documentation**
- **Release Notes**: `RELEASE_NOTES_v[VERSION].md`
- **Upload Guide**: This document

## 🎯 **Key Changes in This Release**

### 🐛 **[CHANGE_CATEGORY]**
- **[CHANGE_TYPE]**: [DESCRIPTION]
- **IMPACT**: [IMPACT_DESCRIPTION]

## 📊 **Version Information**

| Property | Value |
|----------|--------|
| **Version** | [VERSION]+[BUILD] |
| **Previous Version** | [PREV_VERSION]+[PREV_BUILD] |
| **Release Date** | [DATE] |
| **Build Type** | Release |
| **Target SDK** | Android 7.0+ (API 24+) |

## 📱 **Installation Instructions**

### For End Users
```bash
# Download APK
wget https://github.com/omd0/fussi_lib/releases/download/v[VERSION]/fussi_library_v[VERSION].apk

# Install via ADB
adb install fussi_library_v[VERSION].apk
```

## ✅ **Quality Assurance**

### 🧪 **Testing Completed**
- ✅ [TEST_ITEM]
- ✅ [TEST_ITEM]
- ✅ [TEST_ITEM]

### 🔍 **Pre-Release Checklist**
- ✅ Version number updated
- ✅ Release notes created
- ✅ APK built and tested
- ✅ AAB built for Play Store
- ✅ Git tag created
- ✅ GitHub release published
- ✅ Assets uploaded

## 🚀 **Ready for Distribution**

**Distribution Status**: ✅ **LIVE ON GITHUB RELEASES**
```

---

## ✅ **Step 9: Final Commit and Verification**

### 9.1 Commit Documentation
```bash
# Add upload ready documentation
git add release/UPLOAD_READY_v[VERSION].md
git commit -m "📋 Add upload ready documentation for v[VERSION]"
git push origin main
```

### 9.2 Verify Release
```bash
# Check release exists
gh release list --limit 5

# Verify release URL
echo "Release URL: https://github.com/omd0/fussi_lib/releases/tag/v[VERSION]"
```

---

## 🎯 **Quick Reference Commands**

### Essential Commands Sequence
```bash
# 1. Update version in pubspec.yaml manually
# 2. Create release notes manually
# 3. Build assets
flutter build apk --release
flutter build appbundle --release

# 4. Copy assets
cp build/app/outputs/flutter-apk/app-release.apk release/fussi_library_v[VERSION].apk
cp build/app/outputs/bundle/release/app-release.aab release/fussi_library_v[VERSION].aab

# 5. Commit and push
git add .
git commit -m "🚀 Release v[VERSION] - [TITLE]"
git push origin main

# 6. Create and push tag
git tag -a v[VERSION] -m "Release v[VERSION]"
git push origin v[VERSION]

# 7. Create GitHub release
gh release create v[VERSION] \
  --title "🚀 Fussi Library v[VERSION] - [TITLE]" \
  --notes-file release/RELEASE_NOTES_v[VERSION].md \
  release/fussi_library_v[VERSION].apk \
  release/fussi_library_v[VERSION].aab
```

---

## 📝 **Template Variables Reference**

| Variable | Example | Description |
|----------|---------|-------------|
| `[VERSION]` | `1.1.2` | Version number (x.y.z) |
| `[BUILD]` | `5` | Build number |
| `[RELEASE_TITLE]` | `Critical Bug Fixes` | Short release description |
| `[RELEASE_TYPE]` | `Patch` | Major/Minor/Patch |
| `[SIZE]` | `24.5` | File size in MB |
| `[DATE]` | `December 2024` | Release date |
| `[CHANGE_TYPE]` | `FIXED/ADDED/IMPROVED` | Type of change |
| `[PRIORITY]` | `Critical/High/Medium/Low` | Priority level |

---

## 🔄 **Post-Release Actions**

### Optional Steps
1. **Update README** with new version info
2. **Notify users** about the release
3. **Update documentation** if needed
4. **Plan next release** based on feedback

### Monitoring
- Watch for issues on GitHub
- Monitor download statistics
- Collect user feedback

---

## 🎉 **Success Checklist**

After completing all steps, verify:

- ✅ Version updated in `pubspec.yaml`
- ✅ Release notes created and comprehensive
- ✅ APK built successfully
- ✅ AAB built successfully
- ✅ Files copied to release directory
- ✅ Changes committed and pushed
- ✅ Git tag created and pushed
- ✅ GitHub release published with assets
- ✅ Upload ready documentation created
- ✅ Release URL accessible
- ✅ Download links working

**🎯 Release Complete!** 🎉

---

*Save this file and use it as a template for every release. Simply replace the template variables with actual values for each release.* 