import 'dart:convert';
import 'package:http/http.dart' as http;

class QwenMarkdownCleaner {
  QwenMarkdownCleaner({
    required this.apiKey,
    this.baseUrl = const String.fromEnvironment(
      'QWEN_BASE_URL',
      defaultValue:
          'https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1/responses',
    ),
    this.model = const String.fromEnvironment(
      'QWEN_MODEL',
      defaultValue: 'qwen3.5-flash',
    ),
  });

  final String apiKey;
  final String baseUrl;
  final String model;

  static const String _systemPrompt = r'''
你是“PDF->Markdown 清洗器”。
任务：对用户提供的 Markdown 原文做清洗与重排，返回可读性更强的 Markdown。
严格要求：
1) 删除所有表格（包含 Markdown table、网格表、以及明显是表格转出来的对齐文本块）。
2) 删除所有“图片提取出的文字/说明/识别结果”（例如：图片：、图x、Figure、Image OCR、截图文字、图注等），以及明显来自图片的零散识别文本块。
3) 其余正文要保留信息，按语义分段，必要时补充标题层级（##/###）。
4) 不要输出任何解释、前后缀、或代码块包裹，只输出整理后的 Markdown 正文。
''';

  Future<String> cleanMarkdown(String markdown) async {
    final chunks = splitByLength(markdown, 6000);
    final out = StringBuffer();

    for (var i = 0; i < chunks.length; i++) {
      final cleaned = await cleanChunk(
        chunk: chunks[i],
        index: i + 1,
        total: chunks.length,
      );
      if (cleaned.trim().isEmpty) continue;
      if (out.isNotEmpty) out.writeln('\n');
      out.write(cleaned.trimRight());
    }

    return out.toString().trim();
  }

  Future<String> cleanChunk({
    required String chunk,
    required int index,
    required int total,
  }) async {
    final out = StringBuffer();
    await for (final delta in cleanChunkStream(
      chunk: chunk,
      index: index,
      total: total,
    )) {
      out.write(delta);
    }
    return out.toString().trim();
  }

  Stream<String> cleanChunkStream({
    required String chunk,
    required int index,
    required int total,
  }) async* {
    final uri = Uri.parse(baseUrl);
    final input =
        '$_systemPrompt\n\n第 $index/$total 段原文如下（Markdown）：\n\n$chunk';
    final body = jsonEncode({
      'model': model,
      'input': input,
      'stream': true,
      'parameters': {
        'enable_thinking': false,
      },
    });

    final client = http.Client();
    try {
      final req = http.Request('POST', uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'Accept': 'text/event-stream',
        })
        ..body = body;

      final resp = await client.send(req);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final bytes = await resp.stream.toBytes();
        throw Exception(
          'qwen http ${resp.statusCode}: ${utf8.decode(bytes)}',
        );
      }

      var pending = '';
      String? last;

      await for (final line in resp.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final t = line.trimRight();

        if (t.isEmpty) continue;

        if (!t.startsWith('data:')) continue;
        final data = t.substring(5).trimLeft();
        if (data == '[DONE]') return;
        if (data.isEmpty) continue;

        dynamic obj;
        try {
          obj = jsonDecode(data);
        } catch (_) {
          pending += data;
          try {
            obj = jsonDecode(pending);
            pending = '';
          } catch (_) {
            continue;
          }
        }

        final full = _extractOutputText(obj);
        if (full.isEmpty) continue;

        if (last == null) {
          last = full;
          yield full;
        } else if (full.length > last.length && full.startsWith(last)) {
          final delta = full.substring(last.length);
          last = full;
          if (delta.isNotEmpty) yield delta;
        }
      }
    } finally {
      client.close();
    }
  }

  static String _extractOutputText(dynamic root) {
    final buf = StringBuffer();

    void walk(dynamic v) {
      if (v is Map) {
        final type = v['type'];
        final text = v['text'];
        if (type is String &&
            type == 'output_text' &&
            text is String &&
            text.isNotEmpty) {
          if (buf.isNotEmpty) buf.writeln('\n');
          buf.write(text);
        }
        v.forEach((_, vv) => walk(vv));
      } else if (v is List) {
        for (final e in v) {
          walk(e);
        }
      }
    }

    walk(root);
    return buf.toString();
  }

  static List<String> splitByLength(String s, int maxLen) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return const [];
    if (trimmed.length <= maxLen) return [trimmed];

    final lines = trimmed.split('\n');
    final chunks = <String>[];
    final buf = StringBuffer();

    void flush() {
      final t = buf.toString().trimRight();
      if (t.isNotEmpty) chunks.add(t);
      buf.clear();
    }

    for (final line in lines) {
      if (buf.length + line.length + 1 > maxLen && buf.isNotEmpty) flush();
      if (line.length > maxLen) {
        var start = 0;
        while (start < line.length) {
          final end = (start + maxLen < line.length) ? start + maxLen : line.length;
          final part = line.substring(start, end);
          if (buf.isNotEmpty) flush();
          chunks.add(part);
          start = end;
        }
        continue;
      }
      buf.writeln(line);
    }
    flush();
    return chunks;
  }
}

