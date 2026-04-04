import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    this.title = 'PDF',
  });

  final String pdfUrl;
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isDownloading = false;
  double _progress = 0;

  String _fileNameFromUrl(String url) {
    try {
      final u = Uri.parse(url);
      final name = u.pathSegments.isNotEmpty ? u.pathSegments.last : 'schedule.pdf';
      return name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
    } catch (_) {
      return 'schedule.pdf';
    }
  }

  Future<String> _downloadToTempFile() async {
    final dio = Dio();
    final dir = await getTemporaryDirectory();

    final fileName = _fileNameFromUrl(widget.pdfUrl);
    final tempPath = '${dir.path}/$fileName';

    // If already exists, overwrite it
    final f = File(tempPath);
    if (await f.exists()) {
      await f.delete();
    }

    await dio.download(
      widget.pdfUrl,
      tempPath,
      options: Options(
        followRedirects: true,
        receiveTimeout: const Duration(seconds: 60),
      ),
      onReceiveProgress: (received, total) {
        if (!mounted) return;
        if (total > 0) {
          setState(() => _progress = received / total);
        }
      },
    );

    return tempPath;
  }

  Future<void> _downloadAndSave() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      final tempPath = await _downloadToTempFile();

      // Opens system "Save to..." dialog (Downloads/Files)
      final savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: tempPath,
          fileName: _fileNameFromUrl(widget.pdfUrl),
        ),
      );

      if (!mounted) return;

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download cancelled")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF saved to: $savedPath")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to download PDF: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _progress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(widget.pdfUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Download',
            onPressed: _isDownloading ? null : _downloadAndSave,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Open in browser',
            onPressed: uri == null
                ? null
                : () => launchUrl(uri, mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
        bottom: _isDownloading
            ? PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_progress > 0 && _progress <= 1) ? _progress : null),
        )
            : null,
      ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
        onDocumentLoadFailed: (details) {
          // Optional: show an error if PDF cannot be loaded
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load PDF: ${details.description}"), backgroundColor: Colors.red),
          );
        },
      ),
    );
  }
}