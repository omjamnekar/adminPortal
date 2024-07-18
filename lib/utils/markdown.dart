// DELETE THIS FILE ONCE SUPER EDITOR IS UPDATED
// Note: using the standard function crashes with h1 tags

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:super_editor/super_editor.dart';

// TODO: return a regular Document instead of a MutableDocument.
//       For now, we return MutableDocument because DocumentEditor
//       requires one. When the editing system matures, there should
//       be a way to return something here that is not concrete.
MutableDocument deserializeMarkdownToDocument(String markdown) {
  final markdownLines = const LineSplitter().convert(markdown);

  final markdownDoc = md.Document(
    blockSyntaxes: [const _EmptyParagraphSyntax()],
  );
  final blockParser = md.BlockParser(markdownLines, markdownDoc);

  // Parse markdown string to structured markdown.
  final markdownNodes = blockParser.parseLines();

  // Convert structured markdown to a Document.
  final nodeVisitor = _MarkdownToDocument();
  for (final node in markdownNodes) {
    node.accept(nodeVisitor);
  }

  return MutableDocument(nodes: nodeVisitor.content);
}

String serializeDocumentToMarkdown(Document doc) {
  final StringBuffer buffer = StringBuffer();

  bool isFirstLine = true;
  for (int i = 0; i < doc.nodes.length; ++i) {
    final node = doc.nodes[i];

    if (!isFirstLine) {
      // Create a new line to encode the given node.
      buffer.writeln('');
    } else {
      isFirstLine = false;
    }

    if (node is ImageNode) {
      buffer.write('![${node.altText}](${node.imageUrl})');
    } else if (node is HorizontalRuleNode) {
      buffer.write('---');
    } else if (node is ListItemNode) {
      final indent = List.generate(node.indent + 1, (index) => '  ').join('');
      final symbol = node.type == ListItemType.unordered ? '*' : '1.';

      buffer.write('$indent$symbol ${node.text.toMarkdown()}');

      final nodeBelow = i < doc.nodes.length - 1 ? doc.nodes[i + 1] : null;
      if (nodeBelow != null && (nodeBelow is! ListItemNode)) {
        // This list item is the last item in the list. Add an extra
        // blank line after it.
        buffer.writeln('');
      }
    } else if (node is ParagraphNode) {
      final Attribution blockType = node.getMetadataValue('blockType');

      if (blockType == header1Attribution) {
        buffer.write('# ${node.text.toMarkdown()}');
      } else if (blockType == header2Attribution) {
        buffer.write('## ${node.text.toMarkdown()}');
      } else if (blockType == header3Attribution) {
        buffer.write('### ${node.text.toMarkdown()}');
      } else if (blockType == header4Attribution) {
        buffer.write('#### ${node.text.toMarkdown()}');
      } else if (blockType == header5Attribution) {
        buffer.write('##### ${node.text.toMarkdown()}');
      } else if (blockType == header6Attribution) {
        buffer.write('###### ${node.text.toMarkdown()}');
      } else if (blockType == blockquoteAttribution) {
        // TODO: handle multiline
        buffer.write('> ${node.text.toMarkdown()}');
      } else if (blockType == codeAttribution) {
        buffer //
          ..writeln('```') //
          ..writeln(node.text.toMarkdown()) //
          ..write('```');
      } else {
        buffer.write(node.text.toMarkdown());
      }

      // Separates paragraphs with blank lines.
      // If we are at the last node we don't add a trailing
      // blank line.
      if (i != doc.nodes.length - 1) {
        buffer.writeln();
      }
    }
  }

  return buffer.toString();
}

/// Converts structured markdown to a list of [DocumentNode]s.
///
/// To use [_MarkdownToDocument], obtain a series of markdown
/// nodes from a [BlockParser] (from the markdown package) and
/// then visit each of the nodes with a [_MarkdownToDocument].
/// After visiting all markdown nodes, [_MarkdownToDocument]
/// contains [DocumentNode]s that correspond to the visited
/// markdown content.
class _MarkdownToDocument implements md.NodeVisitor {
  _MarkdownToDocument();

  final _content = <DocumentNode>[];
  List<DocumentNode> get content => _content;

  final _listItemTypeStack = <ListItemType>[];

  @override
  bool visitElementBefore(md.Element element) {
    // TODO: re-organize parsing such that visitElementBefore collects
    //       the block type info and then visitText and visitElementAfter
    //       take the action to create the node (#153)
    switch (element.tag) {
      case 'h1':
        _addHeader(element, level: 1);
        break;
      case 'h2':
        _addHeader(element, level: 2);
        break;
      case 'h3':
        _addHeader(element, level: 3);
        break;
      case 'h4':
        _addHeader(element, level: 4);
        break;
      case 'h5':
        _addHeader(element, level: 5);
        break;
      case 'h6':
        _addHeader(element, level: 6);
        break;
      case 'p':
        final inlineVisitor = _parseInline(element);

        if (inlineVisitor.isImage) {
          _addImage(
            // TODO: handle null image URL
            imageUrl: inlineVisitor.imageUrl!,
            altText: inlineVisitor.imageAltText!,
          );
        } else {
          _addParagraph(inlineVisitor.attributedText);
        }
        break;
      case 'blockquote':
        _addBlockquote(element);

        // Skip child elements within a blockquote so that we don't
        // add another node for the paragraph that comprises the blockquote
        return false;
      case 'code':
        _addCodeBlock(element);
        break;
      case 'ul':
        // A list just started. Push that list type on top of the list type stack.
        _listItemTypeStack.add(ListItemType.unordered);
        break;
      case 'ol':
        // A list just started. Push that list type on top of the list type stack.
        _listItemTypeStack.add(ListItemType.ordered);
        break;
      case 'li':
        if (_listItemTypeStack.isEmpty) {
          throw Exception(
              'Tried to parse a markdown list item but the list item type was null');
        }

        _addListItem(
          element,
          listItemType: _listItemTypeStack.last,
          indent: _listItemTypeStack.length - 1,
        );
        break;
      case 'hr':
        _addHorizontalRule();
        break;
    }

    return true;
  }

  @override
  void visitElementAfter(md.Element element) {
    switch (element.tag) {
      // A list has ended. Pop the most recent list type from the stack.
      case 'ul':
      case 'ol':
        _listItemTypeStack.removeLast();
        break;
    }
  }

  @override
  void visitText(md.Text text) {
    // no-op: this visitor is block-level only
  }

  void _addHeader(md.Element element, {int? level}) {
    Attribution? headerAttribution;
    switch (level) {
      case 1:
        headerAttribution = header1Attribution;
        break;
      case 2:
        headerAttribution = header2Attribution;
        break;
      case 3:
        headerAttribution = header3Attribution;
        break;
      case 4:
        headerAttribution = header4Attribution;
        break;
      case 5:
        headerAttribution = header5Attribution;
        break;
      case 6:
        headerAttribution = header6Attribution;
        break;
    }

    _content.add(
      ParagraphNode(
        id: Editor.createNodeId(),
        text: _parseInlineText(element),
        metadata: <String, dynamic>{
          'blockType': headerAttribution,
        },
      ),
    );
  }

  void _addParagraph(AttributedText attributedText) {
    _content.add(
      ParagraphNode(
        id: Editor.createNodeId(),
        text: attributedText,
      ),
    );
  }

  void _addBlockquote(md.Element element) {
    _content.add(
      ParagraphNode(
        id: Editor.createNodeId(),
        text: _parseInlineText(element),
        metadata: <String, dynamic>{
          'blockType': blockquoteAttribution,
        },
      ),
    );
  }

  void _addCodeBlock(md.Element element) {
    // TODO: we may need to replace escape characters with literals here
    // CodeSampleNode(
    //   code: element.textContent //
    //       .replaceAll('&lt;', '<') //
    //       .replaceAll('&gt;', '>') //
    //       .trim(),
    // ),

    _content.add(
      ParagraphNode(
        id: Editor.createNodeId(),
        text: AttributedText(
          element.textContent,
        ),
        metadata: <String, dynamic>{
          'blockType': codeAttribution,
        },
      ),
    );
  }

  void _addImage({
    required String imageUrl,
    required String altText,
  }) {
    _content.add(
      ImageNode(
        id: Editor.createNodeId(),
        imageUrl: imageUrl,
        altText: altText,
      ),
    );
  }

  void _addHorizontalRule() {
    _content.add(HorizontalRuleNode(
      id: Editor.createNodeId(),
    ));
  }

  void _addListItem(
    md.Element element, {
    required ListItemType listItemType,
    required int indent,
  }) {
    _content.add(
      ListItemNode(
        id: Editor.createNodeId(),
        itemType: listItemType,
        indent: indent,
        text: _parseInlineText(element),
      ),
    );
  }

  AttributedText _parseInlineText(md.Element element) {
    final inlineVisitor = _parseInline(element);
    return inlineVisitor.attributedText;
  }

  _InlineMarkdownToDocument _parseInline(md.Element element) {
    final inlineParser = md.InlineParser(element.textContent, md.Document());
    final inlineVisitor = _InlineMarkdownToDocument();
    final inlineNodes = inlineParser.parse();
    for (final inlineNode in inlineNodes) {
      inlineNode.accept(inlineVisitor);
    }
    return inlineVisitor;
  }
}

/// Parses inline markdown content.
///
/// Apply [_InlineMarkdownToDocument] to a text [Element] to
/// obtain an [AttributedText] that represents the inline
/// styles within the given text.
///
/// Apply [_InlineMarkdownToDocument] to an [Element] whose
/// content is an image tag to obtain image data.
///
/// [_InlineMarkdownToDocument] does not support parsing text
/// that contains image tags. If any non-image text is found,
/// the content is treated as styled text.
class _InlineMarkdownToDocument implements md.NodeVisitor {
  _InlineMarkdownToDocument();

  // For our purposes, we only support block-level images. Therefore,
  // if we find an image without any text, we're parsing an image.
  // Otherwise, if there is any text, then we're parsing a paragraph
  // and we ignore the image.
  bool get isImage => _imageUrl != null && attributedText.text.isEmpty;

  String? _imageUrl;
  String? get imageUrl => _imageUrl;

  String? _imageAltText;
  String? get imageAltText => _imageAltText;

  AttributedText get attributedText => _textStack.first;

  final List<AttributedText> _textStack = [AttributedText()];

  @override
  bool visitElementBefore(md.Element element) {
    if (element.tag == 'img') {
      // TODO: handle missing "src" attribute
      _imageUrl = element.attributes['src'];
      _imageAltText = element.attributes['alt'] ?? '';
      return true;
    }

    _textStack.add(AttributedText());

    return true;
  }

  @override
  void visitText(md.Text text) {
    final attributedText = _textStack.removeLast();
    _textStack.add(attributedText.copyAndAppend(AttributedText(text.text)));
  }

  @override
  void visitElementAfter(md.Element element) {
    // Reset to normal text style because a plain text element does
    // not receive a call to visitElementBefore().
    final styledText = _textStack.removeLast();

    if (element.tag == 'strong') {
      styledText.addAttribution(
        boldAttribution,
        SpanRange(
          0,
          styledText.text.length - 1,
        ),
      );
    } else if (element.tag == 'em') {
      styledText.addAttribution(
        italicsAttribution,
        SpanRange(
          0,
          styledText.text.length - 1,
        ),
      );
    } else if (element.tag == 'a') {
      styledText.addAttribution(
        LinkAttribution(url: Uri.parse(element.attributes['href']!)),
        SpanRange(
          0,
          styledText.text.length - 1,
        ),
      );
    }

    if (_textStack.isNotEmpty) {
      final surroundingText = _textStack.removeLast();
      _textStack.add(surroundingText.copyAndAppend(styledText));
    } else {
      _textStack.add(styledText);
    }
  }
}

extension Markdown on AttributedText {
  String toMarkdown() {
    final serializer = AttributedTextMarkdownSerializer();
    return serializer.serialize(this);
  }
}

/// Serializes an [AttributedText] into markdown format
class AttributedTextMarkdownSerializer extends AttributionVisitor {
  late String _fullText;
  StringBuffer? _buffer;
  late int _bufferCursor;

  String serialize(AttributedText attributedText) {
    _fullText = attributedText.text;
    _buffer = StringBuffer();
    _bufferCursor = 0;
    attributedText.visitAttributions(this);
    return _buffer.toString();
  }

  @override
  void visitAttributions(
    AttributedText fullText,
    int index,
    Set<Attribution> startingAttributions,
    Set<Attribution> endingAttributions,
  ) {
    // Write out the text between the end of the last markers, and these new markers.
    _buffer!.write(
      fullText.text.substring(_bufferCursor, index),
    );

    // Add start markers.
    if (startingAttributions.isNotEmpty) {
      final markdownStyles = _sortAndSerializeAttributions(
          startingAttributions, AttributionVisitEvent.start);
      // Links are different from the plain styles since they are both not NamedAttributions (and therefore
      // can't be checked using equality comparison) and asymmetrical in markdown.
      final linkMarker =
          _encodeLinkMarker(startingAttributions, AttributionVisitEvent.start);

      _buffer!
        ..write(linkMarker)
        ..write(markdownStyles);
    }

    // Write out the character at this index.
    _buffer!.write(_fullText[index]);
    _bufferCursor = index + 1;

    // Add end markers.
    if (endingAttributions.isNotEmpty) {
      final markdownStyles = _sortAndSerializeAttributions(
          endingAttributions, AttributionVisitEvent.end);
      // Links are different from the plain styles since they are both not NamedAttributions (and therefore
      // can't be checked using equality comparison) and asymmetrical in markdown.
      final linkMarker =
          _encodeLinkMarker(endingAttributions, AttributionVisitEvent.end);

      // +1 on end index because this visitor has inclusive indices
      // whereas substring() expects an exclusive ending index.
      _buffer!
        ..write(markdownStyles)
        ..write(linkMarker);
    }
  }

  @override
  void onVisitEnd() {
    // When the last span has no attributions, we still have text that wasn't added to the buffer yet.
    if (_bufferCursor <= _fullText.length - 1) {
      _buffer!.write(_fullText.substring(_bufferCursor));
    }
  }

  /// Serializes style attributions into markdown syntax in a repeatable
  /// order such that opening and closing styles match each other on
  /// the opening and closing ends of a span.
  static String _sortAndSerializeAttributions(
      Set<Attribution> attributions, AttributionVisitEvent event) {
    const startOrder = [
      codeAttribution,
      boldAttribution,
      italicsAttribution,
      strikethroughAttribution
    ];

    final buffer = StringBuffer();
    final encodingOrder =
        event == AttributionVisitEvent.start ? startOrder : startOrder.reversed;

    for (final markdownStyleAttribution in encodingOrder) {
      if (attributions.contains(markdownStyleAttribution)) {
        buffer.write(_encodeMarkdownStyle(markdownStyleAttribution));
      }
    }

    return buffer.toString();
  }

  static String _encodeMarkdownStyle(Attribution attribution) {
    if (attribution == codeAttribution) {
      return '`';
    } else if (attribution == boldAttribution) {
      return '**';
    } else if (attribution == italicsAttribution) {
      return '*';
    } else if (attribution == strikethroughAttribution) {
      return '~';
    } else {
      return '';
    }
  }

  /// Checks for the presence of a link in the attributions and returns the characters necessary to represent it
  /// at the open or closing boundary of the attribution, depending on the event.
  static String _encodeLinkMarker(
      Set<Attribution> attributions, AttributionVisitEvent event) {
    final linkAttributions =
        attributions.where((element) => element is LinkAttribution);
    if (linkAttributions.isNotEmpty) {
      final linkAttribution = linkAttributions.first as LinkAttribution;

      if (event == AttributionVisitEvent.start) {
        return '[';
      } else {
        return '](${linkAttribution.url.toString()})';
      }
    }
    return '';
  }
}

/// The line contains only whitespace or is empty.
final _emptyParagraphPattern = RegExp(r'^(?:[ \t]*)$');

/// Parses blank lines as separators and empty paragraphs.
class _EmptyParagraphSyntax extends md.BlockSyntax {
  const _EmptyParagraphSyntax();

  @override
  RegExp get pattern => _emptyParagraphPattern;

  @override
  md.Node? parse(md.BlockParser parser) {
    parser.encounteredBlankLine = true;
    parser.advance();

    // If we get one single blank line, then it's treated as
    // a separator and it's ignored.
    if (!_emptyParagraphPattern.hasMatch(parser.current)) {
      return null;
    }

    // If we get two consecutive blank lines, then the second one
    // is treated as an empty paragraph.
    parser.encounteredBlankLine = false;
    parser.advance();
    return md.Element('p', []);
  }
}
