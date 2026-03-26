import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class OpenDataLoader {
  static Future<String> pdf(Uint8List pdfBytes) => pdfToMarkdown(pdfBytes);

  static Future<String> pdfToMarkdown(Uint8List pdfBytes) async {
    final document = PdfDocument(inputBytes: pdfBytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();
    return text.trim().isEmpty ? '' : text;
  }
}

