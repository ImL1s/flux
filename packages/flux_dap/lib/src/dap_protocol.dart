/// DAP Protocol message types and constants
class DapProtocol {
  // Message types
  static const String typeRequest = 'request';
  static const String typeResponse = 'response';
  static const String typeEvent = 'event';

  // Common commands
  static const String cmdInitialize = 'initialize';
  static const String cmdLaunch = 'launch';
  static const String cmdAttach = 'attach';
  static const String cmdDisconnect = 'disconnect';
  static const String cmdTerminate = 'terminate';

  // Breakpoint commands
  static const String cmdSetBreakpoints = 'setBreakpoints';
  static const String cmdSetFunctionBreakpoints = 'setFunctionBreakpoints';
  static const String cmdSetExceptionBreakpoints = 'setExceptionBreakpoints';
  static const String cmdConfigurationDone = 'configurationDone';

  // Execution commands
  static const String cmdContinue = 'continue';
  static const String cmdNext = 'next';
  static const String cmdStepIn = 'stepIn';
  static const String cmdStepOut = 'stepOut';
  static const String cmdPause = 'pause';

  // Data inspection commands
  static const String cmdThreads = 'threads';
  static const String cmdStackTrace = 'stackTrace';
  static const String cmdScopes = 'scopes';
  static const String cmdVariables = 'variables';
  static const String cmdEvaluate = 'evaluate';

  // Events
  static const String evtInitialized = 'initialized';
  static const String evtStopped = 'stopped';
  static const String evtContinued = 'continued';
  static const String evtExited = 'exited';
  static const String evtTerminated = 'terminated';
  static const String evtThread = 'thread';
  static const String evtOutput = 'output';
  static const String evtBreakpoint = 'breakpoint';

  // Stop reasons
  static const String reasonBreakpoint = 'breakpoint';
  static const String reasonStep = 'step';
  static const String reasonPause = 'pause';
  static const String reasonException = 'exception';
  static const String reasonEntry = 'entry';
}
