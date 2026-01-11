# Setup Guide: Deploy Flutter Hotel App to GitHub Pages

## Quick Start

Your Flutter app is now ready to be deployed to GitHub Pages! Follow these steps:

### Step 1: Add All Files and Make Initial Commit

```powershell
cd c:\xampp2\htdocs\hotel\Flutter_hotel
git add .
git commit -m "Initial commit - Hotel management Flutter app"
```

### Step 2: Push to GitHub

```powershell
git branch -M main
git push -u origin main
```

**Note**: If the repository is not empty on GitHub, you may need to pull first:
```powershell
git pull origin main --allow-unrelated-histories
```

### Step 3: Enable GitHub Pages

1. Go to https://github.com/mohagy/hotel1
2. Click **Settings** (top menu)
3. Scroll down to **Pages** (left sidebar)
4. Under **Source**, select **GitHub Actions**
5. Click **Save**

### Step 4: Verify Deployment

1. Go to the **Actions** tab in your GitHub repository
2. You should see the workflow "Deploy Flutter Web to GitHub Pages" running
3. Wait for it to complete (usually 3-5 minutes)
4. Your app will be live at: **https://mohagy.github.io/hotel1/**

## Important Configuration

### Base URL

The app is configured with base href `/hotel1/` to match your repository name. If you want to change this:

1. Edit `.github/workflows/deploy.yml`
2. Change `--base-href /hotel1/` to your desired path
3. Update any hardcoded URLs in your code

### Firebase Configuration

Make sure your Firebase configuration (`lib/firebase_options.dart`) is set up correctly. The same Firebase project will be used for production.

### Custom Domain (Optional)

If you want to use a custom domain:

1. In GitHub Pages settings, enter your custom domain
2. Update DNS records as instructed
3. Rebuild with `--base-href /` instead of `/hotel1/`

## Updating the App

To update your deployed app:

```powershell
# Make your changes, then:
git add .
git commit -m "Your update message"
git push origin main
```

GitHub Actions will automatically rebuild and redeploy your app.

## Troubleshooting

### Workflow Fails

- Check the **Actions** tab for error messages
- Ensure all dependencies are in `pubspec.yaml`
- Verify Flutter version compatibility

### Pages Not Loading

- Check browser console for errors
- Verify the base-href matches your repository name
- Ensure Firebase configuration is correct

### Build Errors

- Run `flutter clean` locally
- Run `flutter pub get`
- Test build locally: `flutter build web --base-href /hotel1/`

## Support

For issues or questions, contact: nathonheart@gmail.com

