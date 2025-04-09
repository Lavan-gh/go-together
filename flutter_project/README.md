# Flutter Project

This is a Flutter application that demonstrates the use of custom widgets for buttons and input fields. The project includes screens for login, registration, and home, showcasing how to utilize these custom widgets effectively.

## Project Structure

```
flutter_project
├── lib
│   ├── main.dart          # Entry point of the application
│   ├── screens
│   │   ├── home.dart      # Home screen
│   │   ├── login.dart     # Login screen
│   │   └── register.dart   # Registration screen
│   ├── widgets
│   │   ├── custom_button.dart  # Custom button widget
│   │   └── custom_input.dart   # Custom input field widget
```

## Custom Widgets

### CustomButton

The `CustomButton` widget is a reusable button that can be styled and configured with a callback function.

**Properties:**
- `onPressed`: Function to be called when the button is pressed.
- `child`: Widget displayed inside the button.
- `style`: Optional styling for the button.

### CustomInput

The `CustomInput` widget is a reusable input field that can be used for text input, including password fields.

**Properties:**
- `controller`: A `TextEditingController` to manage the input text.
- `label`: A string that sets the label text for the input field.
- `obscureText`: Boolean to determine if the text should be obscured (for passwords).
- `decoration`: Optional decoration for the input field.

## Setup Instructions

1. Clone the repository or download the project files.
2. Navigate to the project directory.
3. Run `flutter pub get` to install the necessary dependencies.
4. Use `flutter run` to start the application.

## Usage Examples

In the `login.dart`, `register.dart`, and `home.dart` files, you can import and use the `CustomButton` and `CustomInput` widgets as follows:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/custom_button.dart';
import 'package:flutter_project/widgets/custom_input.dart';
```

You can then create instances of these widgets in your screen's build method to create a consistent and reusable UI across your application.