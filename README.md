# PocketLM

PocketLM is a Flutter-based Android app for running small language models locally on-device. It lets users browse a catalog of compact GGUF models, download the one they want, and chat with it without sending data to the cloud.

The app is designed for privacy-first, offline AI experiences on mobile devices, especially for smaller models that can run on-device with reasonable memory and CPU/GPU support.

## Why PocketLM

- 100% offline model usage after download
- Local model catalog with saved downloads
- Lightweight SLM support for phones and tablets
- Private chat experience without external server dependency
- Simple user interface focused on local inference

## Features

- Download GGUF model files from Hugging Face
- Keep track of already-downloaded models locally
- Load a selected model from device storage
- Stream responses token by token while generating
- Stop generation mid-response
- Keep a clean chat-style interface for local conversations
- Support for Android with local runtime inference using llama.cpp-based Android integration

## Included model catalog

The app currently includes models such as:

- Gemma 3 4B
- Gemma 4 E2B
- Bonsai 8B
- Phi-4 Mini
- Bonsai 4B
- Gemma 3 1B
- Qwen 2.5 3B
- TinyLlama 1.1B

These are lightweight options intended for local execution.

## Tech stack

- Flutter
- Dart
- Android platform
- `llama_flutter_android` for local model inference
- `shared_preferences` for saved model state
- `path_provider` for device storage access
- `dio` for download handling
- `flutter_svg` for app artwork

## App architecture

The project is organized into a simple layered structure:

- `lib/main.dart` — app entry and shell
- `lib/screens/` — chat and model selection screens
- `lib/services/` — model management, downloads, and inference
- `lib/models/` — model metadata definitions
- `lib/widgets/` — reusable UI components
- `lib/utils/` — constants and shared app values
- `assets/` — model logos and static assets

## How it works

1. User opens the app and goes to the Models screen.
2. User downloads a GGUF model from a remote source.
3. The app stores the model ID locally in SharedPreferences.
4. The selected model is loaded from the device storage.
5. The user chats with the model locally using on-device inference.

## Requirements

Before running the project, make sure you have:

- Flutter SDK 3.x or newer
- Android Studio / Android SDK
- An Android emulator or physical Android device
- Sufficient device storage for downloaded models
- Enough RAM depending on the model size you choose

## Setup

Clone the repository:

```bash
git clone https://github.com/your-username/PocketLM.git
cd PocketLM
```

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

For Android emulator or real device, ensure USB debugging / emulator is ready.

## Recommended usage

- Start with a smaller model such as Bonsai 4B or Gemma 3 1B if your device has limited memory.
- Use larger models only if your device can handle the model size and runtime requirements.
- Download models while connected to Wi-Fi because model files can be several hundred MB to a few GB.

## Project structure

```text
PocketLM/
├── android/
├── assets/
├── frontend/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── utils/
│   └── widgets/
├── test/
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
└── ...
```

## Notes

- This project is focused on offline local inference and privacy-oriented AI use.
- Model downloads depend on internet access during the first download.
- After download, the app can operate without a backend server.
- Inference performance depends on device hardware, model size, and available memory.

## License

This project is currently a local development project and may use open-source packages under their respective licenses. Please check the relevant package licenses before distribution or commercial use.

## Contributing

Contributions are welcome. If you want to improve the app, add new model support, refine the UI, or improve inference handling, open a pull request with a clear description.

## Contact

For questions, suggestions, or feedback, feel free to open an issue or reach out through the repository.
