import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

import 'open_data_loader.dart';
import 'qwen_markdown_cleaner.dart';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF转Markdown小工具',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'PDF转Markdown小工具'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _markdown = '';
  bool _loading = false;
  bool _cleaning = false;
  double _cleanProgress = 0;
  String? _error;
  String? _pdfName;
  int _jobId = 0;
  String _apiKey = const String.fromEnvironment('QWEN_API_KEY');

  Future<void> _editApiKey() async {
    final controller = TextEditingController(text: _apiKey);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('设置 API Key'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: '请输入 Qwen API Key',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      final key = result.trim();
      setState(() {
        _apiKey = key;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(key.isEmpty ? 'API Key已清空' : 'API Key保存成功')),
        );
      }
    }
  }

  Future<void> _exportMarkdown() async {
    if (_markdown.trim().isEmpty) return;
    try {
      final base = (_pdfName ?? 'export')
          .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      final bytes = Uint8List.fromList(utf8.encode(_markdown));
      if (kIsWeb) {
        final ok = downloadTextFile('$base.md', _markdown);
        if (!ok) throw Exception('web download failed');
        return;
      }
      if (Platform.isAndroid || Platform.isIOS) {
        await FilePicker.platform.saveFile(
          dialogTitle: 'Export Markdown',
          fileName: '$base.md',
          type: FileType.custom,
          allowedExtensions: const ['md'],
          bytes: bytes,
        );
        return;
      }
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Markdown',
        fileName: '$base.md',
        type: FileType.custom,
        allowedExtensions: const ['md'],
      );
      if (savePath == null || savePath.trim().isEmpty) return;
      final path = savePath.toLowerCase().endsWith('.md')
          ? savePath
          : '$savePath.md';
      await File(path).writeAsString(_markdown);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _pickAndConvertPdf() async {
    final jobId = ++_jobId;
    setState(() {
      _loading = true;
      _cleaning = false;
      _cleanProgress = 0;
      _error = null;
    });

    try {
      final apiKey = _apiKey.trim();
      if (apiKey.isEmpty) {
        throw Exception('missing QWEN_API_KEY');
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (bytes == null) {
        setState(() => _loading = false);
        return;
      }
      _pdfName = file?.name;

      final md = await OpenDataLoader.pdf(bytes);
      setState(() {
        _markdown = md;
        _loading = false;
        _cleaning = true;
        _cleanProgress = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF导入成功')),
        );
      }

      () async {
        try {
          final cleaner = QwenMarkdownCleaner(apiKey: apiKey);
          final chunks = QwenMarkdownCleaner.splitByLength(md, 6000);
          final cleanedChunks = List<String>.filled(chunks.length, '');

          for (var i = 0; i < chunks.length; i++) {
            if (_jobId != jobId) return;
            final sb = StringBuffer();
            await for (final delta in cleaner.cleanChunkStream(
              chunk: chunks[i],
              index: i + 1,
              total: chunks.length,
            )) {
              if (_jobId != jobId) return;
              sb.write(delta);
              cleanedChunks[i] = sb.toString().trimRight();
              setState(() {
                _markdown = cleanedChunks
                    .where((x) => x.trim().isNotEmpty)
                    .join('\n\n');
                _cleanProgress = chunks.isEmpty ? 1 : (i + 0.5) / chunks.length;
              });
            }
            cleanedChunks[i] = sb.toString().trimRight();
            if (_jobId != jobId) return;
            setState(() {
              _markdown =
                  cleanedChunks.where((x) => x.trim().isNotEmpty).join('\n\n');
              _cleanProgress = chunks.isEmpty ? 1 : (i + 1) / chunks.length;
            });
          }

          if (_jobId != jobId) return;
          setState(() {
            _cleaning = false;
            _cleanProgress = 1;
          });
        } catch (e) {
          if (_jobId != jobId) return;
          setState(() {
            _cleaning = false;
            _error = '清洗失败: $e';
          });
        }
      }();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _cleaning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final renderMarkdown =
        _markdown.contains(r'\n') ? _markdown.replaceAll(r'\n', '\n') : _markdown;
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(_pdfName == null || _pdfName!.isEmpty ? widget.title : _pdfName!),
        actions: [
          IconButton(
            onPressed: _editApiKey,
            icon: const Icon(Icons.key),
            tooltip: 'Set API Key',
          ),
          IconButton(
            onPressed: _markdown.trim().isEmpty ? null : _exportMarkdown,
            icon: const Icon(Icons.download),
            tooltip: 'Export Markdown',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (_cleaning)
                LinearProgressIndicator(
                  value: _cleanProgress == 0 ? null : _cleanProgress,
                ),
              if (_cleaning) const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? SelectableText(_error!)
                        : renderMarkdown.isEmpty
                            ? const Center(child: Text('请选择一个 PDF'))
                            : Markdown(
                                data: renderMarkdown,
                                selectable: true,
                                builders: {
                                  'latex': LatexElementBuilder(
                                    textStyle: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                },
                                extensionSet: md.ExtensionSet(
                                  [
                                    ...md.ExtensionSet.gitHubFlavored
                                        .blockSyntaxes,
                                    LatexBlockSyntax(),
                                  ],
                                  [
                                    ...md.ExtensionSet.gitHubFlavored
                                        .inlineSyntaxes,
                                    LatexInlineSyntax(),
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndConvertPdf,
        tooltip: 'Upload PDF',
        child: const Icon(Icons.upload_file),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
