# Troubleshooting: Workflow Not Showing in Actions Tab

## Quick Check

1. **Verify the file exists on GitHub:**
   - Go to https://github.com/mohagy/hotel1
   - Click the **Code** tab
   - Navigate to `.github/workflows/deploy.yml`
   - If you can see the file, it's been pushed correctly

2. **Check Actions Tab:**
   - Click the **Actions** tab
   - If you see "Get started with GitHub Actions" or "Choose a workflow", the workflow file might not be detected yet
   - Try refreshing the page (Ctrl+F5)

3. **Manual Trigger (if file exists):**
   - Go to Actions tab
   - If you see workflows listed, click "Deploy Flutter Web to GitHub Pages"
   - Click "Run workflow" button (top right)
   - Select "main" branch
   - Click "Run workflow"

## If File Doesn't Exist on GitHub

The workflow file might not have been pushed. Run these commands:

```powershell
cd c:\xampp2\htdocs\hotel\Flutter_hotel

# Check if file exists locally
dir .github\workflows\deploy.yml

# If it exists, add and commit it
git add .github/workflows/deploy.yml
git commit -m "Add GitHub Actions workflow"
git push origin main
```

## If File Exists But Workflow Doesn't Run

1. **Check file syntax:**
   - Make sure the YAML file is valid
   - Check for indentation errors (YAML is sensitive to spaces)

2. **Verify branch name:**
   - The workflow triggers on pushes to `main` branch
   - Make sure you're pushing to `main`, not `master`

3. **Wait a moment:**
   - Sometimes GitHub takes 30-60 seconds to detect new workflow files
   - Refresh the Actions tab

4. **Check repository settings:**
   - Go to Settings → Actions → General
   - Make sure "Allow all actions and reusable workflows" is selected

