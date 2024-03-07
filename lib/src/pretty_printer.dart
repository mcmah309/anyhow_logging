import 'ansi_color.dart';
import 'log.dart';
import 'level.dart';
import 'printer.dart';

/// [PrettyPrinter] for output.
class PrettyPrinter implements Printer {
  static const topLeftCorner = '┌';
  static const bottomLeftCorner = '└';
  static const middleCorner = '├';
  static const verticalLine = '│';
  static const doubleDivider = '─';
  static const singleDivider = '┄';

  static final Map<Level, String> defaultLevelEmojis = {
    //Level.trace: '',
    Level.debug: '🐛',
    Level.info: '💡',
    Level.warning: '⚠️',
    Level.error: '⛔',
    //Level.fatal: '👾',
  };

  static final Map<Level, AnsiColor> defaultLevelColors = {
    //Level.trace: AnsiColor(54), // purple
    Level.debug: const AnsiColor(82), // green
    Level.info: const AnsiColor(12), // blue
    Level.warning: const AnsiColor(208), // orange
    Level.error: const AnsiColor(124), // red
    //Level.fatal: const AnsiColor(199), // bright red
  };

  /// Controls the length of the divider lines.
  final int lineLength;

  /// Whether ansi colors are used to color the output.
  final bool colors;

  /// Whether emojis are prefixed to the log line.
  final bool printEmojis;

  /// Controls the colors used for the different log levels.
  ///
  /// Default fallbacks are modifiable via [defaultLevelColors].
  final Map<Level, AnsiColor>? levelColors;

  /// Controls the emojis used for the different log levels.
  ///
  /// Default fallbacks are modifiable via [defaultLevelEmojis].
  final Map<Level, String>? levelEmojis;

  final bool willBoxOuput;

  String _topBorder = '';
  //String _middleBorder = '';
  String _bottomBorder = '';

  PrettyPrinter({
    this.lineLength = 120,
    this.colors = true,
    this.printEmojis = true,
    this.levelColors,
    this.levelEmojis,
    this.willBoxOuput = true,
  }) {
    var doubleDividerLine = StringBuffer();
    var singleDividerLine = StringBuffer();
    for (var i = 0; i < lineLength - 1; i++) {
      doubleDividerLine.write(doubleDivider);
      singleDividerLine.write(singleDivider);
    }

    _topBorder = '$topLeftCorner$doubleDividerLine';
    //_middleBorder = '$middleCorner$singleDividerLine';
    _bottomBorder = '$bottomLeftCorner$doubleDividerLine';
  }

  AnsiColor _getLevelColor(Level level) {
    AnsiColor? color;
    if (colors) {
      color = levelColors?[level] ?? PrettyPrinter.defaultLevelColors[level];
    }
    return color ?? const AnsiColor.none();
  }

  String _getEmoji(Level level) {
    if (printEmojis) {
      final String? emoji = levelEmojis?[level] ?? defaultLevelEmojis[level];
      if (emoji != null) {
        return '$emoji ';
      }
    }
    return '';
  }

  @override
  List<String> format(
    Level level,
    List<OutputEntry> entries,
  ) {
    List<String> buffer = [];
    var verticalLineAtLevel = willBoxOuput ? '$verticalLine ' : '';
    var color = _getLevelColor(level);
    if (willBoxOuput) buffer.add(color(_topBorder));

    var emoji = _getEmoji(level);
    for (var entry in entries) {
      buffer.add(
          '${color('$verticalLineAtLevel$emoji${entry.header}: ')}${entry.headerMessage ?? ''}');
      if (entry.body != null) {
        for (var line in entry.body!.split("\n")) {
          buffer.add('${color(verticalLineAtLevel)}\t$line');
        }
      }
    }
    if (willBoxOuput) buffer.add(color(_bottomBorder));

    return buffer;
  }
}
