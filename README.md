# ConvertPDF

## What it does

- Import a PDF file
- Extract text and convert it to Markdown
- Clean the Markdown with Qwen in chunks (remove tables / image-OCR text, restructure paragraphs) while streaming updates to the UI

## Run

```bash
flutter pub get
flutter run -d windows --dart-define=QWEN_API_KEY=sk-xxx
```

Optional:

```bash
flutter run -d windows --dart-define=QWEN_API_KEY=sk-xxx --dart-define=QWEN_BASE_URL=https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1/responses --dart-define=QWEN_MODEL=qwen3.5-flash
```
