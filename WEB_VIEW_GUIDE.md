# 🌐 Flutter App - Web View Guide

## ✅ Status
- **Flutter Web:** ✅ Enabled
- **Chrome:** ✅ Available
- **Edge:** ✅ Available
- **Dependencies:** ✅ Installed

---

## 🚀 Quick Start - Run Flutter App in Web Browser

### Method 1: Run in Chrome (Recommended)
```powershell
cd Flutter_hotel
flutter run -d chrome
```

### Method 2: Run in Edge
```powershell
cd Flutter_hotel
flutter run -d edge
```

### Method 3: Build for Web and Serve Locally
```powershell
# Build web version
flutter build web

# The build output will be in: build/web/
# You can serve it using any web server or open index.html directly
```

---

## 🌍 Access URLs

### During Development (Hot Reload)
When you run `flutter run -d chrome`, Flutter will:
1. Build the web app
2. Start a development server (usually on port 8080 or random port)
3. Automatically open Chrome with the app
4. Display the URL in the terminal (e.g., `http://localhost:8080`)

**Example Output:**
```
Launching lib\main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...
This is taking an unusually long time. [message repeats]
Flutter run key commands.
...
🔥  To hot restart changes while running, press "r". To hot reload individual changes instead, press "R".
...
✓  Built build/web (release mode)
The Flutter DevTools debugger and profiler on Chrome is available at: http://127.0.0.1:9100/?uri=http://127.0.0.1:54731/
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h Repeat this help message.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

Flutter DevTools URL: http://127.0.0.1:9100/?uri=http://127.0.0.1:54731/
```

### Built Web App
After running `flutter build web`, access the app via:
- **Local File:** `file:///C:/xampp2/htdocs/hotel/Flutter_hotel/build/web/index.html`
- **XAMPP Apache:** `http://localhost/hotel/Flutter_hotel/build/web/`
- **Or serve with any web server**

---

## 📋 Commands Reference

### Check Flutter Setup
```powershell
flutter doctor          # Check Flutter installation
flutter devices         # List available devices (including web browsers)
flutter config --enable-web  # Enable web support (already done)
```

### Run Commands
```powershell
flutter run -d chrome          # Run in Chrome (default)
flutter run -d edge            # Run in Edge
flutter run -d chrome --web-port 8080  # Specify port
flutter run -d chrome --release  # Release mode (faster, no hot reload)
```

### Build Commands
```powershell
flutter build web              # Build for web (production)
flutter build web --release    # Build in release mode (optimized)
flutter build web --web-renderer html  # Use HTML renderer
flutter build web --web-renderer canvaskit  # Use CanvasKit renderer (default)
```

### Development Commands (While Running)
- **`r`** - Hot reload (quick refresh, keeps state)
- **`R`** - Hot restart (full restart, resets state)
- **`q`** - Quit application
- **`d`** - Detach (stop Flutter CLI but keep app running)
- **`c`** - Clear screen

---

## 🔧 Configuration

### API Base URL
The app needs to connect to your PHP backend. Update the API configuration:

**File:** `lib/config/api_config.dart`

```dart
class ApiConfig {
  // For local development
  static const String baseUrl = 'http://localhost/hotel';
  
  // For production
  // static const String baseUrl = 'https://tin.neuereatec.com/hotel';
}
```

### CORS Issues
If you encounter CORS (Cross-Origin Resource Sharing) errors when accessing PHP APIs from web:

**Solution:** Add CORS headers to your PHP API files or `.htaccess`:

```php
// At the top of your PHP API files
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
```

### Firebase Web Configuration
The Flutter app uses Firebase. Ensure Firebase is configured for web:

1. Check `lib/config/firebase_config.dart` or `lib/firebase_options.dart`
2. Firebase should automatically work for web if configured correctly
3. Check browser console for Firebase initialization errors

---

## 🐛 Troubleshooting

### Issue: "No devices found" or "Chrome not detected"
**Solution:**
```powershell
flutter config --enable-web
flutter doctor -v  # Check detailed status
```

### Issue: App doesn't load or shows blank page
**Possible Causes:**
1. **CORS errors** - Check browser console (F12) for CORS messages
2. **API connection issues** - Verify PHP backend is running
3. **Firebase errors** - Check Firebase configuration
4. **Build errors** - Check terminal output for compilation errors

**Solution:**
- Open browser DevTools (F12)
- Check Console tab for errors
- Check Network tab for failed API calls
- Check if XAMPP Apache is running

### Issue: Hot reload not working
**Solution:**
- Use `R` for hot restart instead of `r`
- Or stop and restart: `q` then `flutter run -d chrome`

### Issue: Port already in use
**Solution:**
```powershell
flutter run -d chrome --web-port 8081  # Use different port
```

### Issue: Build errors
**Solution:**
```powershell
flutter clean           # Clean build cache
flutter pub get         # Reinstall dependencies
flutter build web       # Try building again
```

---

## 🌐 Serving Built Web App

After building with `flutter build web`, you have several options:

### Option 1: Serve with Python
```powershell
cd build/web
python -m http.server 8000
# Access at: http://localhost:8000
```

### Option 2: Serve with Node.js (http-server)
```powershell
npm install -g http-server
cd build/web
http-server -p 8000
# Access at: http://localhost:8000
```

### Option 3: Copy to XAMPP htdocs
```powershell
# Copy build/web contents to a new directory
xcopy /E /I build\web C:\xampp2\htdocs\hotel\flutter_app
# Access at: http://localhost/hotel/flutter_app/
```

### Option 4: Serve with Flutter's built-in server
```powershell
flutter run -d chrome --web-port 8080
```

---

## 📱 Testing Different Browsers

### Chrome
```powershell
flutter run -d chrome
```

### Edge
```powershell
flutter run -d edge
```

### Firefox (if installed)
```powershell
flutter config --enable-web
flutter run -d web-server  # Then manually open in Firefox
```

---

## 🎯 Development Workflow

1. **Start Development Server:**
   ```powershell
   cd Flutter_hotel
   flutter run -d chrome
   ```

2. **Make Code Changes:**
   - Edit files in `lib/`
   - Save the file

3. **Hot Reload:**
   - Press `r` in terminal for hot reload
   - Press `R` for hot restart
   - Changes appear instantly in browser

4. **Test Features:**
   - Check browser console (F12) for errors
   - Test API calls in Network tab
   - Verify Firebase connections

5. **Build for Production:**
   ```powershell
   flutter build web --release
   ```

---

## 🔗 Important URLs

- **DevTools:** Automatically opened URL in terminal during `flutter run`
- **Local App:** Usually `http://localhost:XXXX` (port shown in terminal)
- **Production Build:** `build/web/index.html`

---

## 💡 Tips

1. **Use Chrome DevTools** (F12) for debugging:
   - Console: JavaScript/Dart errors
   - Network: API calls and responses
   - Application: Local storage, cookies
   - Performance: Check rendering performance

2. **Hot Reload vs Hot Restart:**
   - Hot Reload (`r`): Fast, keeps app state
   - Hot Restart (`R`): Slower, resets app state (useful for debugging state issues)

3. **Release Mode:**
   - Use `flutter run -d chrome --release` for production-like performance
   - Faster, optimized, but no hot reload

4. **Multiple Tabs:**
   - You can run multiple instances on different ports
   - `flutter run -d chrome --web-port 8080`
   - `flutter run -d chrome --web-port 8081` (in another terminal)

---

## ✅ Quick Checklist

- [ ] Flutter web enabled (`flutter config --enable-web`)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Chrome/Edge browser available
- [ ] PHP backend running (XAMPP Apache)
- [ ] API base URL configured correctly
- [ ] Firebase configured for web
- [ ] No CORS errors in browser console

---

## 🚀 Quick Start Command

```powershell
cd C:\xampp2\htdocs\hotel\Flutter_hotel
flutter run -d chrome
```

This will:
1. Build the Flutter web app
2. Start development server
3. Open Chrome automatically
4. Display the app URL
5. Enable hot reload for instant updates

