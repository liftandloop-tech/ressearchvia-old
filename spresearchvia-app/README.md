# spresearchvia

SP ResearchVia

## Getting Started

This project is a starting point for a Flutter application.

### Prerequisites & Setup

1. **Install Flutter & Dart Plugins**
   - Go to **Settings/Preferences** → **Plugins**.
   - Search for **Flutter** and install it (this will also install Dart automatically).
   - Restart Android Studio.

2. **Configure Flutter SDK**
   - Go to **Settings/Preferences** → **Languages & Frameworks** → **Flutter**.
   - Set the **Flutter SDK path** (where you installed Flutter).
   - Example: `/Users/yourname/flutter` or `C:\src\flutter`.

3. **Create a Run/Debug Configuration**
   - At the top toolbar, click the dropdown next to the green **Run ▶️** button.
   - Select **Edit Configurations...**.
   - Click **+** → choose **Flutter**.
   - Set:
     - **Name**: e.g., `main.dart`
     - **Dart entrypoint**: `lib/main.dart`
   - Apply and Save.

4. **Connect a Device**
   - Plug in an Android phone with USB debugging enabled or start an emulator.
   - Ensure it appears in the device selector at the top of Android Studio.

5. **Run the Project**
   - Click **Run ▶️**.
   - Android Studio will build and launch your Flutter app on the selected device.

---

## Architecture Guidelines

### Controller vs. Screen Lifecycle
To ensure data freshness and prevent stale data issues, we strictly follow this rule:

**Rule: Controllers must never initiate network calls in `onInit`. All fetching is screen-owned.**

*   **Controllers (`GetxController`):** Use `onInit` ONLY for setup (stream subscriptions, local storage initialization, argument parsing). Do NOT call API fetch methods here.
*   **Screens (`StatefulWidget`):** Network calls should be triggered in the screen's `initState` (often using `addPostFrameCallback`) or via user actions. This ensures data is fetched fresh every time the user navigates to the screen.

Example Pattern:
```dart
// Controller
void onInit() {
  super.onInit();
  // ✅ OK: Setup listeners
  // ❌ BAD: fetchApiData(); 
}

Future<void> fetchData() async { ... }

// Screen
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.fetchData(); // ✅ Correct
  });
}
```

---

## Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter Documentation](https://docs.flutter.dev/)
