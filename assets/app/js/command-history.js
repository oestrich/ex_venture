/**
 * Command Histroy Tracking.
 *
 * Allows for scrolling forwards and backwards through history easily. Tracks
 * current location inside and will pass it to a function on scroll.
 */
class CommandHistory {
  /**
   * @constructor
   */
  constructor() {
    this.history = []
    this.index = -1
  }

  /**
   * Add a command to the history. Will limit to 10 commands.
   * @param {string} command
   */
  add(command) {
    if (command != "") {
      this.index = -1
      this.history.unshift(command)
      if (this.history.length > 10) {
        this.history.pop()
      }
    }
  }

  /**
   * Scroll backwards in history.
   * @param {function} fun The command will be passed in as the
   *    only argument to the function
   */
  scrollBack(fun) {
    if (this.history[this.index + 1] != undefined) {
      this.index += 1
      fun(this.history[this.index])
    }
  }

  /**
   * Scroll forwards in history. Will pass an empty string if the
   * end of the list has been reached.
   *
   * @param {function} fun The command will be passed in as the
   *    only argument to the function
   */
  scrollForward(fun) {
    if (this.history[this.index - 1] != undefined) {
      this.index -= 1
      fun(this.history[this.index])
    } else if (this.index - 1 <= -1) {
      this.index = -1
      fun("")
    }
  }
}

export default CommandHistory;
