import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' show Rect;

class SocialStoryExportService {
  Future<void> exportPng({
    required Uint8List bytes,
    required String fileName,
    Rect? sharePositionOrigin,
  }) async {
    final blob = html.Blob([bytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = '$fileName.png'
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
