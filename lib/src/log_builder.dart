part of "log.dart";



final defaultLogConfig = LogLevelConfig.def(
  Level.info,
  printer: PrettyPrinter(),
);

class LogLevelConfig {
  /// The level of the log.
  final Level level;
  /// The printer to use to print the log.
  final Printer printer;
  /// If stacktrace is encountered, the number of frames to keep. If null, the entire stacktrace is kept.
  final int? framesToKeep;
  /// The components to use to build the log.
  final List<LogComponent> components;

  bool _willCreateLogId = false;
  bool _willCaptureTime = false;
  bool _willCreateStackTraceForLogPoint = false;

  LogLevelConfig.def(this.level, {this.printer = const SimplePrinter(), this.framesToKeep = 6})
      : components = const [
          ObjectTypeLogComponent(),
          StringifiedLogComponent(),
          AppendLogComponent(),
          IdLogComponent(),
          TimeLogComponent(),
          LogPointComponent(),
        ],
        _willCreateLogId = true,
        _willCaptureTime = true,
        _willCreateStackTraceForLogPoint = true;

  LogLevelConfig(this.level, {required this.components, this.printer = const SimplePrinter(), this.framesToKeep = 6}) {
    for (final component in components) {
      for (final toCapture in component.toCapture) {
        switch (toCapture) {
          case ToCapture.id:
            _willCreateLogId = true;
            break;
          case ToCapture.time:
            _willCaptureTime = true;
            break;
          case ToCapture.logPoint:
            _willCreateStackTraceForLogPoint = true;
            break;
        }
      }
    }
  }

  @override
  bool operator ==(Object other) {
    return other is LogLevelConfig && other.level == level;
  }

  @override
  int get hashCode => level.hashCode;
}

enum ToCapture {
  id,
  time,
  logPoint,
}

abstract class LogComponent {
  /// Additional information to capture for the log.
  List<ToCapture> get toCapture;

  const LogComponent();

  LogField? build(LogEvent event);
}

class ObjectTypeLogComponent extends LogComponent {
  const ObjectTypeLogComponent();

  @override
  LogField build(LogEvent event) {
    return LogField(
      header: 'Object Type',
      headerMessage: event.obj.runtimeType.toString(),
    );
  }

  /// Guarentees the [LogEvent] will have the [ToCapture] field.
  @override
  List<ToCapture> get toCapture => const [];
}

class StringifiedLogComponent extends LogComponent {
  final int ifHasStacktraceKeep;

  const StringifiedLogComponent({this.ifHasStacktraceKeep = 6});

  @override
  LogField build(LogEvent event) {
    final header = event.override == null ? 'Stringified' : 'Stringified Override';
    final message = event.override ?? event.obj;
    return LogField(
      header: header,
      body: message,
    );
  }

  @override
  List<ToCapture> get toCapture => const [];
}

class AppendLogComponent extends LogComponent {
  const AppendLogComponent();

  @override
  LogField? build(LogEvent event) {
    if (event.append == null) {
      return null;
    }
    return LogField(
      header: 'Appended Message',
      headerMessage: event.append!,
    );
  }

  @override
  List<ToCapture> get toCapture => const [];
}

class IdLogComponent extends LogComponent {
  const IdLogComponent();

  @override
  LogField build(LogEvent event) {
    return LogField(
      header: 'Log ID',
      headerMessage: event.id!,
    );
  }

  @override
  List<ToCapture> get toCapture => const [ToCapture.id];
}

enum TimeZone { local, utc }

class TimeLogComponent extends LogComponent {
  final TimeZone time;

  // Dev Note: The time is always originally in UTC.
  const TimeLogComponent([this.time = TimeZone.utc]);

  @override
  LogField build(LogEvent event) {
    return LogField(
        header: 'Log Time',
        headerMessage: switch (time) {
          TimeZone.local => event.time!.toLocal().toIso8601String(),
          TimeZone.utc => event.time!.toIso8601String(),
        });
  }

  @override
  List<ToCapture> get toCapture => const [ToCapture.time];
}

class LogPointComponent extends LogComponent {
  /// The number of frames to keep in the stack trace.
  final int framesToKeep;

  const LogPointComponent({this.framesToKeep = 6});

  @override
  LogField build(LogEvent event) {
    return LogField(
        header: 'Object StackTrace',
        body: event.logPointStackTrace!,
    );
  }

  @override
  List<ToCapture> get toCapture => const [ToCapture.logPoint];
}
