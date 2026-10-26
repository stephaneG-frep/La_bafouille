/// Balisage volontairement réduit : aucun HTML arbitraire n'est interprété.
class TextRun {
  const TextRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });
  final String text;
  final bool bold, italic, underline;
}

List<TextRun> parseMarkup(String source) {
  final result = <TextRun>[];
  var bold = false, italic = false, underline = false;
  var buffer = StringBuffer();
  void flush() {
    if (buffer.isNotEmpty) {
      result.add(
        TextRun(
          buffer.toString(),
          bold: bold,
          italic: italic,
          underline: underline,
        ),
      );
      buffer = StringBuffer();
    }
  }

  for (var i = 0; i < source.length;) {
    if (source.startsWith('**', i) &&
        (bold || source.indexOf('**', i + 2) >= 0)) {
      flush();
      bold = !bold;
      i += 2;
    } else if (source.startsWith('*', i) &&
        (italic || source.indexOf('*', i + 1) >= 0)) {
      flush();
      italic = !italic;
      i++;
    } else if (source.startsWith('<u>', i) &&
        source.indexOf('</u>', i + 3) >= 0) {
      flush();
      underline = true;
      i += 3;
    } else if (source.startsWith('</u>', i) && underline) {
      flush();
      underline = false;
      i += 4;
    } else {
      buffer.write(source[i]);
      i++;
    }
  }
  flush();
  return result;
}

String plainText(String source) =>
    parseMarkup(source).map((r) => r.text).join();
