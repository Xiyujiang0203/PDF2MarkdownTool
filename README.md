# ConvertPDF

[English](./README.md) | [简体中文](./README.zh-CN.md)

## What it does

- Import a PDF file
- Extract text and convert it to Markdown
- Clean Markdown with Qwen in chunks (remove tables / image-OCR text, restructure content)
- Stream cleaned output live to the UI
- Render Markdown with LaTeX formula support
- Export current Markdown to a `.md` file
- Set Qwen API Key from the top-right key icon in app

## Online Demo

- GitHub Pages: https://xiyujiang0203.github.io/PDF2MarkdownTool/

## Run

- Device: Windows
```bash
flutter pub get
flutter run -d windows --dart-define=QWEN_API_KEY=sk-xxx
```

- Device: macOS

```bash
flutter pub get
flutter run -d macos --dart-define=QWEN_API_KEY=sk-xxx
```

- Device: iOS Simulator

```bash
flutter pub get
open -a Simulator
flutter run -d ios --dart-define=QWEN_API_KEY=sk-xxx
```

Optional:

- Device: Windows
```bash
flutter run -d windows --dart-define=QWEN_API_KEY=sk-xxx --dart-define=QWEN_BASE_URL=https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1/responses --dart-define=QWEN_MODEL=qwen3.5-flash
```

## Build

Windows EXE:

- Device: Windows
```bash
flutter build windows --release
```

Android APK:

- Device: Android
```bash
flutter build apk --release
```

Web:

- Device: Web
```bash
flutter build web --release
```

Outputs:

`build/windows/x64/runner/Release/convert_pdf.exe`

`build/app/outputs/flutter-apk/app-release.apk`

`build/web`

## Release Downloads

- GitHub Releases: https://github.com/Xiyujiang0203/PDF2MarkdownTool/releases

## CI/CD

- `.github/workflows/flutter-ci-release.yml`: analyze + build APK/EXE, publish release assets on `v*` tags
- `.github/workflows/deploy-web-pages.yml`: auto deploy web to GitHub Pages on `main`

## macOS Notes

- If the app starts in background only, switch back to app via `command + tab`.
- If PDF import has no response, rebuild once after pulling latest:

- Device: macOS
```bash
flutter clean
flutter run -d macos
```

- If cleaning fails with `Operation not permitted` to `dashscope.aliyuncs.com:443`, rebuild once with latest macOS entitlements:

- Device: macOS
```bash
flutter clean
flutter run -d macos
```

## iOS Notes

- If iOS build is stuck at `Running pod install...`, run:

- Device: iOS
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d ios
```
