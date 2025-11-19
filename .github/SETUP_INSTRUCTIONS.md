# GitHub Actions Build Setup Instructions

This guide will help you set up GitHub Actions to automatically build your APK/AAB files.

## Prerequisites

- GitHub account
- Your local repository must be pushed to GitHub
- Your keystore file (`diurecycle-release-key.jks`)

## Step-by-Step Setup

### 1. Encode Your Keystore File

First, you need to convert your keystore to base64 format.

**On Windows PowerShell:**
```powershell
# Navigate to your project directory
cd "C:\Users\Syed Rafi\Desktop\DEV\DIU-Recycle"

# Convert keystore to base64
$keystore = [Convert]::ToBase64String([IO.File]::ReadAllBytes("diurecycle-release-key.jks"))
$keystore | Out-File -FilePath keystore_base64.txt -Encoding utf8
```

This creates a `keystore_base64.txt` file with your encoded keystore.

### 2. Add GitHub Secrets

Go to your GitHub repository:
1. Click **Settings** tab
2. Click **Secrets and variables** → **Actions** (left sidebar)
3. Click **New repository secret**

Add these 4 secrets:

| Secret Name | Value | Where to Find |
|------------|-------|---------------|
| `KEYSTORE_BASE64` | Content of `keystore_base64.txt` | The file you just created |
| `KEYSTORE_PASSWORD` | `Rafi1234` | From your `key.properties` file |
| `KEY_PASSWORD` | `Rafi1234` | From your `key.properties` file |
| `KEY_ALIAS` | `diurecycle` | From your `key.properties` file |

**Important**: After adding secrets, delete the `keystore_base64.txt` file from your local machine for security.

### 3. Push to GitHub

```powershell
# Add all files including workflow
git add .
git commit -m "Add GitHub Actions workflow for automated builds"
git push origin main
```

### 4. Trigger a Build

You have 3 ways to trigger a build:

#### Method 1: Manual Trigger (Recommended for first test)
1. Go to your GitHub repository
2. Click **Actions** tab
3. Click **Build Release APK/AAB** workflow (left sidebar)
4. Click **Run workflow** button (right side)
5. Choose build type: **appbundle** (for Play Store) or **apk** (for testing)
6. Click **Run workflow**

#### Method 2: Automatic on Push
Every time you push to the `main` branch, it automatically builds an AAB.

#### Method 3: Create a Release Tag
```powershell
git tag v1.0.0
git push origin v1.0.0
```
This creates both APK and AAB, and publishes them as a GitHub Release.

## Download Your Build

After the workflow completes (takes ~5-10 minutes):

1. Go to **Actions** tab in GitHub
2. Click on the latest workflow run
3. Scroll down to **Artifacts** section
4. Download `release-aab` (for Play Store) or `release-apk` (for testing)

## Files in This Setup

- `.github/workflows/build-release.yml` - GitHub Actions workflow configuration
- `.github/SETUP_INSTRUCTIONS.md` - This file
- `.gitignore` - Updated to ignore sensitive files

## Security Notes

✅ **Safe to commit:**
- Workflow file (`.github/workflows/build-release.yml`)
- This instruction file

❌ **DO NOT commit:**
- `keystore_base64.txt` (delete after uploading to secrets)
- `diurecycle-release-key.jks` (already in `.gitignore`)
- `android/key.properties` (already in `.gitignore`)
- `.env` file with API keys (already in `.gitignore`)

## Troubleshooting

### Build fails with "Keystore not found"
- Check that `KEYSTORE_BASE64` secret is set correctly
- Make sure you copied the entire content from `keystore_base64.txt`

### Build fails with "Signing config error"
- Verify all 4 secrets are set: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`
- Check that passwords match your `key.properties` file

### Workflow doesn't appear
- Make sure files are in `.github/workflows/` folder
- File must be named `.yml` or `.yaml`
- Push to `main` branch

### Can't find the built file
- Wait for workflow to complete (green checkmark)
- Look in **Artifacts** section at bottom of workflow run page
- Files expire after 7 days (configurable)

## What Happens During Build

1. **Checkout code** - Downloads your repository
2. **Setup Java 17** - Required for Android builds
3. **Setup Flutter 3.35.6** - Installs Flutter SDK
4. **Install dependencies** - Runs `flutter pub get`
5. **Decode keystore** - Converts base64 back to `.jks` file
6. **Create key.properties** - Generates signing configuration
7. **Build** - Runs `flutter build appbundle` or `flutter build apk`
8. **Upload artifact** - Makes the file downloadable

## Next Steps

After downloading your AAB file:
1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to your app → **Production** → **Releases**
3. Click **Create new release**
4. Upload the `app-release.aab` file
5. Complete the release form
6. Submit for review

## Future Updates

To build updated versions:
1. Make changes to your code
2. Update version in `pubspec.yaml` (e.g., `1.0.0+1` → `1.0.1+2`)
3. Commit and push
4. Build automatically triggers, or manually trigger via Actions tab

---

**Need Help?**
- Check the Actions tab for build logs
- Look at the "Build" job for detailed error messages
- Ensure all secrets are set correctly
