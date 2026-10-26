import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models.dart';
import 'markup.dart';

String escapeXml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

class Exports {
  static String html(Letter l) {
    final content = parseMarkup(l.text).map((r) {
      var s = escapeXml(r.text);
      if (r.bold) s = '<strong>$s</strong>';
      if (r.italic) s = '<em>$s</em>';
      if (r.underline) s = '<u>$s</u>';
      return s;
    }).join();
    return '<!doctype html><html lang="fr"><meta charset="utf-8"><title>${escapeXml(l.title)}</title><style>body{max-width:180mm;margin:20mm auto;font:12pt serif;line-height:1.6}article{white-space:pre-wrap;text-align:${l.alignment}}</style><body><article>$content</article></body></html>';
  }

  static Uint8List docx(Letter l) {
    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add(
      '[Content_Types].xml',
      '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>',
    );
    add(
      '_rels/.rels',
      '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>',
    );
    final paragraphs = l.text.split('\n').map((p) {
      final runs = parseMarkup(p)
          .map(
            (r) =>
                '<w:r><w:rPr>${r.bold ? '<w:b/>' : ''}${r.italic ? '<w:i/>' : ''}${r.underline ? '<w:u w:val="single"/>' : ''}</w:rPr><w:t xml:space="preserve">${escapeXml(r.text)}</w:t></w:r>',
          )
          .join();
      return '<w:p><w:pPr><w:jc w:val="${l.alignment == 'justify' ? 'both' : l.alignment}"/></w:pPr>$runs</w:p>';
    }).join();
    add(
      'word/document.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$paragraphs<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/></w:sectPr></w:body></w:document>',
    );
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static Future<Uint8List> pdf(
    Letter l, {
    pw.Font? font,
    pw.Font? bold,
    pw.Font? italic,
    pw.Font? boldItalic,
  }) async {
    final doc = pw.Document();
    final alignment = switch (l.alignment) {
      'center' => pw.TextAlign.center,
      'right' => pw.TextAlign.right,
      'justify' => pw.TextAlign.justify,
      _ => pw.TextAlign.left,
    };
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 200,
        theme: font == null
            ? null
            : pw.ThemeData.withFont(
                base: font,
                bold: bold ?? font,
                italic: italic ?? font,
                boldItalic: boldItalic ?? font,
              ),
        margin: const pw.EdgeInsets.all(48),
        build: (_) => l.text
            .split('\n')
            .map(
              (p) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.RichText(
                  textAlign: alignment,
                  text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 4),
                    children: [
                      for (final r in parseMarkup(p.isEmpty ? ' ' : p))
                        pw.TextSpan(
                          text: r.text,
                          style: pw.TextStyle(
                            fontWeight: r.bold
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                            fontStyle: r.italic
                                ? pw.FontStyle.italic
                                : pw.FontStyle.normal,
                            decoration: r.underline
                                ? pw.TextDecoration.underline
                                : pw.TextDecoration.none,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    return doc.save();
  }
}
