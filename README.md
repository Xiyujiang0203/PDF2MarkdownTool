# ConvertPDF

## What it does

- Import a PDF file
- Extract text and convert it to Markdown
- Clean Markdown with Qwen in chunks (remove tables / image-OCR text, restructure content)
- Stream cleaned output live to the UI
- Render Markdown with LaTeX formula support
- Export current Markdown to a `.md` file
- Set API Key from the top-right key icon in app

## Run

```bash
flutter pub get
flutter run -d windows --dart-define=QWEN_API_KEY=sk-xxx
```

Optional:

```bash
flutter run -d windows --dart-define=QWEN_API_KEY=sk-xxx --dart-define=QWEN_BASE_URL=https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1/responses --dart-define=QWEN_MODEL=qwen3.5-flash
```

## Build (Windows)

```bash
flutter build windows --release
```

Output:

`build/windows/x64/runner/Release/convert_pdf.exe`
