part of '../../parser.dart';

/// IRC Message
class Message {
  /// Original Line
  final String line;

  /// IRC Command
  final String command;

  /// Message
  final String message;
  final String _hostmask;

  /// IRC v3 Tags
  final Map<String, String> tags;

  /// Parameters
  final List<String> parameters;

  /// Creates a new Message
  Message(
      {required this.line,
      hostmask,
      required this.command,
      required this.message,
      required this.parameters,
      required this.tags})
      : _hostmask = hostmask,
        _serverTime =
            DateTime.now(); // Initializing with current time as default

  @override
  String toString() => line;

  late Hostmask _parsedHostmask;
  bool _isHostmaskParsed = false;

  /// Gets the Parsed Hostmask
  Hostmask get hostmask {
    if (!_isHostmaskParsed) {
      _parsedHostmask = Hostmask.parse(_hostmask);
      _isHostmaskParsed = true;
    }
    return _parsedHostmask;
  }

  /// The Plain Hostmask
  String get plainHostmask => _hostmask;

  bool get hasAccountTag => tags.containsKey('account');
  String? get accountTag => tags['account'];

  bool get hasServerTime => tags.containsKey('time');
  DateTime get serverTime {
    return _serverTime;
  }

  bool get isBatched => tags.containsKey('batch');
  String? get batchId => tags['batch'];

  late DateTime _serverTime;
}

/// IRC Parser Helpers
class IrcParserSupport {
  /// Parses IRCv3 Tags from [input].
  ///
  /// [input] should begin with the @ part of the tags
  /// and not include the space at the end.
  static Map<String, String> parseTags(String input) {
    var out = <String, String>{};
    var parts = input.split(';');
    parts.forEach((part) => _testPart(part, out));

    return out;
  }

  /// Parses the ISUPPORT PREFIX Property
  ///
  /// [input] should begin with '(' and contain ')'
  static Map<String, String> parseSupportedPrefixes(String input) {
    var out = <String, String>{};
    var split = input.split(')');
    var modes = split[0].substring(1).split('');
    var prefixes = split[1].split('');

    var i = 0;
    for (var mode in modes) {
      out[mode] = prefixes[i];
      i++;
    }

    return out;
  }

  static ModeChange parseMode(String input) {
    ModeChange mode;
    if (input.startsWith('+')) {
      mode = ModeChange(input.substring(1).split('').toSet(), <String>{});
    } else if (input.startsWith('-')) {
      mode = ModeChange(<String>{}, input.substring(1).split('').toSet());
    } else {
      throw Exception('Failed to parse mode: invalid prefix for ${input}');
    }
    return mode;
  }

  static Map<String, String> _testPart(String part, Map<String, String> out) {
    if (part.contains('=')) {
      var keyValue = part.split('=');
      out[keyValue[0]] = keyValue.skip(1).join('=');
    } else {
      out[part] = 'true';
    }
    return out;
  }
}

class ModeChange {
  final Set<String> added;
  final Set<String> removed;

  Set<String> get modes => isAdded ? added : removed;
  bool get isAdded => added.isNotEmpty;
  bool get isRemoved => removed.isNotEmpty;

  ModeChange(this.added, this.removed);

  @override
  String toString() =>
      added.isEmpty ? '-${removed.join()}' : '+${added.join()}';
}

class Mode {
  final Set<String> modes;

  Mode(this.modes);
  Mode.empty() : modes = <String>{};

  bool has(String x) {
    return modes.contains(x);
  }
}
