/**
 * Logger class
 *
 * Allow setting `window.logger` to optionally turn on logging
 **/
class Logger {
  static log(...message) {
    if (window.logger) {
      window.logger(...message);
    }
  }
}

export default Logger
