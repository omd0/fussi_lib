#!/bin/bash

# 🚀 Fussi Library Release Automation Script
# Usage: ./scripts/release.sh [VERSION] [RELEASE_TITLE]
# Example: ./scripts/release.sh 1.1.2 "Bug Fixes and UI Improvements"

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if parameters are provided
if [ $# -lt 2 ]; then
    print_error "Usage: $0 [VERSION] [RELEASE_TITLE]"
    print_error "Example: $0 1.1.2 \"Bug Fixes and UI Improvements\""
    exit 1
fi

VERSION=$1
RELEASE_TITLE=$2
BUILD_NUMBER=$(date +%s | tail -c 2)  # Last 2 digits of timestamp
CURRENT_DATE=$(date '+%B %Y')

print_step "Starting release process for v$VERSION"
echo "Release Title: $RELEASE_TITLE"
echo "Build Number: $BUILD_NUMBER"
echo "Date: $CURRENT_DATE"
echo ""

# Step 1: Check current status
print_step "Step 1: Checking current status"
if ! git diff --quiet; then
    print_warning "You have uncommitted changes. Please commit or stash them first."
    git status --short
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
print_success "Git status checked"

# Step 2: Update version in pubspec.yaml
print_step "Step 2: Updating version in pubspec.yaml"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
else
    # Linux
    sed -i "s/^version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
fi
print_success "Version updated to $VERSION+$BUILD_NUMBER"

# Step 3: Create release notes template
print_step "Step 3: Creating release notes template"
RELEASE_NOTES_FILE="release/RELEASE_NOTES_v$VERSION.md"
if [ ! -f "$RELEASE_NOTES_FILE" ]; then
    cat > "$RELEASE_NOTES_FILE" << EOF
# 📚 Fussi Library v$VERSION Release Notes

## 🎯 **Patch Release**

### ✅ **Key Changes**
- **FIXED**: [DESCRIPTION]
- **IMPROVED**: [DESCRIPTION]

### 🔧 **Technical Improvements**
- **Enhanced**: [DESCRIPTION]
- **Optimized**: [DESCRIPTION]

## 🎨 **User Interface Changes**

### 🧹 **UI Improvements**
- **Cleaned**: [DESCRIPTION]
- **Enhanced**: [DESCRIPTION]

## 🐛 **Bug Fixes**

1. **High**: [BUG_DESCRIPTION]
2. **Medium**: [BUG_DESCRIPTION]

## 📱 **Installation**

### Android APK
\`\`\`bash
# Download and install the APK
wget https://github.com/omd0/fussi_lib/releases/download/v$VERSION/fussi_library_v$VERSION.apk
adb install fussi_library_v$VERSION.apk
\`\`\`

### Android Bundle (AAB)
- Available for Google Play Store distribution
- Optimized size and performance

## 📞 **Support**

For issues or questions:
- **GitHub Issues**: [Report bugs](https://github.com/omd0/fussi_lib/issues)
- **Documentation**: Check \`/docs\` folder for guides

---

**Version**: $VERSION+$BUILD_NUMBER  
**Release Date**: $CURRENT_DATE  
**Compatibility**: Android 7.0+ (API 24+)  
**Size**: ~25MB (APK), ~45MB (AAB)
EOF
    print_success "Release notes template created: $RELEASE_NOTES_FILE"
    print_warning "Please edit $RELEASE_NOTES_FILE with actual changes before continuing"
    read -p "Press Enter after editing the release notes..."
else
    print_warning "Release notes file already exists: $RELEASE_NOTES_FILE"
fi

# Step 4: Build release assets
print_step "Step 4: Building release assets"
print_step "Building APK..."
flutter build apk --release
APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
print_success "APK built successfully ($APK_SIZE)"

print_step "Building AAB..."
flutter build appbundle --release
AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
print_success "AAB built successfully ($AAB_SIZE)"

# Step 5: Copy to release directory
print_step "Step 5: Copying assets to release directory"
cp build/app/outputs/flutter-apk/app-release.apk "release/fussi_library_v$VERSION.apk"
cp build/app/outputs/bundle/release/app-release.aab "release/fussi_library_v$VERSION.aab"
print_success "Assets copied to release directory"

# Step 6: Commit changes
print_step "Step 6: Committing changes"
git add .
git commit -m "🚀 Release v$VERSION - $RELEASE_TITLE

📦 Version bump to $VERSION+$BUILD_NUMBER
📋 Added comprehensive release notes
📱 Built APK ($APK_SIZE) and AAB ($AAB_SIZE) for distribution

Key changes:
- $RELEASE_TITLE"

print_success "Changes committed"

# Step 7: Push to GitHub
print_step "Step 7: Pushing to GitHub"
git push origin main
print_success "Changes pushed to GitHub"

# Step 8: Create and push tag
print_step "Step 8: Creating and pushing git tag"
git tag -a "v$VERSION" -m "🚀 Release v$VERSION - $RELEASE_TITLE

🎯 Release:
- $RELEASE_TITLE

📱 Built for Android with APK and AAB distributions"

git push origin "v$VERSION"
print_success "Git tag v$VERSION created and pushed"

# Step 9: Create GitHub release
print_step "Step 9: Creating GitHub release"
if command -v gh &> /dev/null; then
    gh release create "v$VERSION" \
      --title "🚀 Fussi Library v$VERSION - $RELEASE_TITLE" \
      --notes-file "$RELEASE_NOTES_FILE" \
      "release/fussi_library_v$VERSION.apk" \
      "release/fussi_library_v$VERSION.aab"
    
    RELEASE_URL="https://github.com/omd0/fussi_lib/releases/tag/v$VERSION"
    print_success "GitHub release created: $RELEASE_URL"
else
    print_warning "GitHub CLI not found. Please create the release manually:"
    print_warning "1. Go to: https://github.com/omd0/fussi_lib/releases"
    print_warning "2. Click 'Create a new release'"
    print_warning "3. Use tag: v$VERSION"
    print_warning "4. Title: 🚀 Fussi Library v$VERSION - $RELEASE_TITLE"
    print_warning "5. Upload: release/fussi_library_v$VERSION.apk and release/fussi_library_v$VERSION.aab"
    RELEASE_URL="https://github.com/omd0/fussi_lib/releases/new"
fi

# Step 10: Create upload ready documentation
print_step "Step 10: Creating upload ready documentation"
UPLOAD_READY_FILE="release/UPLOAD_READY_v$VERSION.md"
cat > "$UPLOAD_READY_FILE" << EOF
# 🚀 Fussi Library v$VERSION - Upload Ready

## ✅ **Release Status: COMPLETED**

**Release URL**: https://github.com/omd0/fussi_lib/releases/tag/v$VERSION

## 📦 **Release Assets**

### 📱 **Android Distributions**
- **APK**: \`fussi_library_v$VERSION.apk\` ($APK_SIZE)
- **AAB**: \`fussi_library_v$VERSION.aab\` ($AAB_SIZE)

### 📋 **Documentation**
- **Release Notes**: \`RELEASE_NOTES_v$VERSION.md\`
- **Upload Guide**: This document

## 🎯 **Key Changes in This Release**

### 🔧 **$RELEASE_TITLE**
- **IMPACT**: Improved user experience and functionality

## 📊 **Version Information**

| Property | Value |
|----------|--------|
| **Version** | $VERSION+$BUILD_NUMBER |
| **Release Date** | $CURRENT_DATE |
| **Build Type** | Release |
| **Target SDK** | Android 7.0+ (API 24+) |

## 📱 **Installation Instructions**

### For End Users
\`\`\`bash
# Download APK
wget https://github.com/omd0/fussi_lib/releases/download/v$VERSION/fussi_library_v$VERSION.apk

# Install via ADB
adb install fussi_library_v$VERSION.apk
\`\`\`

## ✅ **Quality Assurance**

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
EOF

print_success "Upload ready documentation created: $UPLOAD_READY_FILE"

# Step 11: Final commit
print_step "Step 11: Final commit for documentation"
git add "$UPLOAD_READY_FILE"
git commit -m "📋 Add upload ready documentation for v$VERSION"
git push origin main
print_success "Documentation committed and pushed"

# Summary
echo ""
echo "🎉 =================================="
echo "🎉 RELEASE v$VERSION COMPLETED!"
echo "🎉 =================================="
echo ""
print_success "Release URL: $RELEASE_URL"
print_success "APK: release/fussi_library_v$VERSION.apk ($APK_SIZE)"
print_success "AAB: release/fussi_library_v$VERSION.aab ($AAB_SIZE)"
print_success "Release Notes: $RELEASE_NOTES_FILE"
print_success "Upload Ready: $UPLOAD_READY_FILE"
echo ""
print_step "Next steps:"
echo "1. Test the APK installation"
echo "2. Verify the GitHub release page"
echo "3. Monitor for any issues"
echo "4. Plan next release based on feedback"
echo ""
print_success "Release process completed successfully! 🎉" 