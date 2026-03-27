# ConvertPDF

[English](./README.md) | [简体中文](./README.zh-CN.md)

## 功能

- 导入 PDF 文件
- 提取文本并转换为 Markdown
- 使用 Qwen 分块清洗 Markdown（移除表格 / 图片 OCR 文本，重组内容）
- 在界面中实时流式显示清洗结果
- 渲染 Markdown，并支持 LaTeX 公式
- 将当前 Markdown 导出为 `.md` 文件
- 可在应用右上角钥匙图标中设置 Qwen API Key

## 在线体验

- GitHub Pages: https://xiyujiang0203.github.io/PDF2MarkdownTool/

## 运行

```bash
flutter pub get
flutter run -d windows --dart-define=QWEN_API_KEY=sk-xxx
```

可选：

```bash
flutter run -d windows --dart-define=QWEN_API_KEY=sk-xxx --dart-define=QWEN_BASE_URL=https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1/responses --dart-define=QWEN_MODEL=qwen3.5-flash
```

## 构建

Windows EXE：

```bash
flutter build windows --release
```

Android APK：

```bash
flutter build apk --release
```

Web：

```bash
flutter build web --release
```

输出：

`build/windows/x64/runner/Release/convert_pdf.exe`

`build/app/outputs/flutter-apk/app-release.apk`

`build/web`

## 发布下载

- GitHub Releases: https://github.com/Xiyujiang0203/PDF2MarkdownTool/releases

## CI/CD

- `.github/workflows/flutter-ci-release.yml`：代码检查 + 构建 APK/EXE，打 `v*` tag 时自动上传 release 资产
- `.github/workflows/deploy-web-pages.yml`：`main` 分支自动部署 Web 到 GitHub Pages
