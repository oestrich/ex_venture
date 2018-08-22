import React from 'react';
import _ from "lodash";

class Listener extends React.Component {
  constructor(props) {
    super(props);

    this.state = props.listener;
    this.handleUpdate = props.handleUpdate;
    this.handleRemove = this.handleRemove.bind(this);
  }

  handleUpdateField(field) {
    return (event) => {
      let value = event.target.value;
      this.setState({[field]: value});

      let listener = Object.assign(this.state, {[field]: value});
      this.handleUpdate(listener);
    }
  }

  handleRemove(event) {
    event.preventDefault();
    this.props.handleRemove();
  }

  render() {
    let phrase = this.state.phrase;
    let key = this.state.key;

    return (
      <div className="row">
        <div className="col-md-4">
          <label>Phrase Regex</label>
          <input type="text" value={phrase} className="form-control" onChange={this.handleUpdateField("phrase")} />
        </div>
        <div className="col-md-4">
          <label>Next Key</label>
          <input type="text" value={key} className="form-control" onChange={this.handleUpdateField("key")} />
        </div>
        <div className="col-md-1">
          <label style={{visibility: "hidden"}}>Remove</label>
          <a href="#" className="btn btn-warning" onClick={this.handleRemove}>
            <i className="fa fa-times"></i>
          </a>
        </div>
      </div>
    );
  }
}

class Line extends React.Component {
  constructor(props) {
    super(props);

    this.state = props.line;

    this.addListener = this.addListener.bind(this);
    this.castField = this.castField.bind(this);
    this.handleRemoveListener = this.handleRemoveListener.bind(this);
    this.handleUpdate = this.handleUpdate.bind(this);
    this.handleUpdateField = this.handleUpdateField.bind(this);
    this.handleUpdateListener = this.handleUpdateListener.bind(this);
  }

  castField(field, value) {
    switch (field) {
      case "trigger":
        if (value == "none") {
          return null;
        }  else {
          return value;
        }

      case "unknown":
        if (value == "") {
          return null;
        }  else {
          return value;
        }

      default:
        return value;
    }
  }

  handleUpdateField(field) {
    return (event) => {
      let value = event.target.value;
      value = this.castField(field, value);
      this.setState({[field]: value});

      let line = Object.assign(this.state, {[field]: value});
      this.handleUpdate(line);
    }
  }

  handleUpdate(line) {
    this.props.handleUpdate(line, this.props.index);
  }

  addListener(event) {
    event.preventDefault();
    let listener = {
      phrase: "",
      key: "",
    };

    let listeners = [...this.state.listeners, listener];
    this.setState({listeners: listeners});

    let line = Object.assign(this.state, {listeners: listeners});
    this.handleUpdate(line);
  }

  handleUpdateListener(index) {
    return (listener) => {
      let listeners = this.state.listeners;
      listeners[index] = listener;
      this.setState({
        listeners: listeners,
      });

      let line = Object.assign(this.state, {listeners: listeners});
      this.handleUpdate(line);
    };
  }

  handleRemoveListener(index) {
    return () => {
      let listeners = this.state.listeners;
      listeners.splice(index, 1);
      this.setState({listeners: listeners});

      let line = Object.assign(this.state, {listeners: listeners});
      this.handleUpdate(line);
    };
  }

  triggerLine() {
    if (this.state.trigger != "line") {
      return null;
    }

    let key = this.state.triggerNext;
    let delay = this.state.triggerDelay;

    return (
      <div className="row">
        <div className="col-md-6">
          <label>Next Key</label>
          <input type="text" value={key} className="form-control" onChange={this.handleUpdateField("triggerNext")} />
        </div>
        <div className="col-md-6">
          <label>Delay</label>
          <input type="text" value={delay} className="form-control" onChange={this.handleUpdateField("triggerDelay")} />
        </div>
      </div>
    );
  }

  listeners() {
    if (this.state.trigger != null) {
      return null;
    }

    let listeners = this.state.listeners;

    return (
      <div className="row">
        <div className="col-md-12">
          <label>Listeners</label>
          {listeners.map((listener, index) => {
            return (
              <Listener key={index} listener={listener} handleUpdate={this.handleUpdateListener(index)} handleRemove={this.handleRemoveListener(index)} />
            );
          })}
          <br />
          <a href="#" className="btn btn-default" onClick={this.addListener}>Add Listener</a>
        </div>
      </div>
    );
  }

  render() {
    let key = this.state.key;
    let message = this.state.message;
    let trigger = this.state.trigger || "none";
    let unknown = this.state.unknown || "";

    return (
      <div>
        <div className="row">
          <div className="col-md-4">
            <label>Key</label>
            <input type="text" value={key} className="form-control" onChange={this.handleUpdateField("key")} />
          </div>
          <div className="col-md-4">
            <label>Triggers</label>
            <select value={trigger} className="form-control" onChange={this.handleUpdateField("trigger")}>
              <option value="none">None</option>
              <option value="quest">Quest</option>
              <option value="line">Line</option>
            </select>
          </div>
        </div>
        {this.triggerLine()}
        <div className="row">
          <div className="col-md-12">
            <label>Message</label>
            <textarea value={message} className="form-control" onChange={this.handleUpdateField("message")} />
            <span className="help-block">This field has global resources enabled.</span>
          </div>
        </div>
        <div className="row">
          <div className="col-md-12">
            <label>Unknown Response</label>
            <textarea value={unknown} className="form-control" onChange={this.handleUpdateField("unknown")} />
            <span className="help-block">This field has global resources enabled.</span>
          </div>
        </div>
        {this.listeners()}
      </div>
    );
  }
}

class Editor extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      lines: this.convertLines(props.lines),
    }

    this.addLine = this.addLine.bind(this);
    this.handleUpdate = this.handleUpdate.bind(this);
    this.removeLine = this.removeLine.bind(this);
  }

  convertLines(lines) {
    console.log(lines);
    return lines.map(line => {
      let newLine = {
        key: line.key,
        message: line.message,
        trigger: line.trigger,
        unknown: line.unknown,
        listeners: line.listeners,
      };

      if (line.trigger != null && line.trigger != undefined && line.trigger.type == "line") {
        newLine.trigger = line.trigger.type;
        newLine.triggerNext = line.trigger.next;
        newLine.triggerDelay = line.trigger.delay;
      }

      return newLine;
    });
  }

  handleUpdate(line, index) {
    let lines = this.state.lines;
    lines[index] = line;
    this.setState({
      lines: lines,
    });
  }

  addLine(event) {
    event.preventDefault();

    let line = {
      key: "",
      message: "",
      trigger: null,
      triggerDelay: 0.5,
      triggerNext: "",
      unknown: null,
      listeners: [],
    };

    let lines = this.state.lines;

    this.setState({
      lines: [...lines, line],
    });
  }

  removeLine(index) {
    let lines = this.state.lines;
    lines.splice(index, 1);
    this.setState({lines: lines});
  }

  toJSON() {
    let script =this.state.lines.map(line => {
      switch(line.trigger) {
        case "quest":
          return _.pick(line, ['key', 'trigger', 'message', 'unknown']);

        case "line":
          let newLine = _.pick(line, ['key', 'trigger', 'message', 'unknown']);
          newLine['trigger'] = {
            type: 'line',
            next: line.triggerNext,
            delay: parseFloat(line.triggerDelay),
          };
          return newLine;

        default:
          return _.pick(line, ['key', 'listeners', 'message', 'unknown']);
      }
    });
    return JSON.stringify(script);
  }

  render() {
    let lines = this.state.lines;
    let handleUpdate = this.handleUpdate;

    let scriptJSON = this.toJSON();
    let removeLine = this.removeLine;

    return (
      <div className="form-group">
        <input type="hidden" name={this.props.name} value={scriptJSON} />

        <label className="col-md-4">Script</label>
        <div className="col-md-8">
          {lines.map((line, index) => {
            let onClick = (event) => {
              event.preventDefault();
              removeLine(index);
            }

            return (
              <div key={index}>
                <Line line={line} index={index} handleUpdate={handleUpdate} />
                <a href="#" onClick={onClick}>Remove</a>
                <hr />
              </div>
            );
          })}

          <a href="#" className="btn btn-primary" onClick={this.addLine}>Add Line</a>
        </div>
      </div>
    );
  }
}

class Tester extends React.Component {
  constructor(props) {
    super(props);

    let startLine = props.script.find(line => {
      return line.key == "start";
    });

    this.state = {
      lines: [{
        name: this.props.giver_name,
        message: startLine.message,
      }],
      currentLine: startLine,
      message: "",
    }

    this.handleMessage = this.handleMessage.bind(this);
    this.handleEnter = this.handleEnter.bind(this);
    this.nextLine = this.nextLine.bind(this);

    this.state = this.attemptLineAdvance(this.state);
  }

  handleMessage(event) {
    this.setState({message: event.target.value});
  }

  handleEnter(event) {
    if (event.key == "Enter") {
      event.preventDefault();
      let line = this.nextLine(this.state.message);

      let state = this.state;
      state.currentLine = line;
      state.lines = [
        ...this.state.lines,
        {name: "Player", message: this.state.message},
        {name: this.props.giver_name, message: line.message},
      ];
      state.message = "";

      state = this.attemptLineAdvance(this.state);

      this.setState(state);
    }
  }

  nextLine(message) {
    let line = this.state.currentLine;

    let listener = line.listeners.find(listener => {
      let regex = new RegExp(listener.phrase);
      return message.match(regex);
    });

    if (listener) {
      return this.props.script.find(line => {
        return line.key == listener.key;
      });
    } else {
      return this.props.script.find(line => {
        return line.key == "start";
      });
    }
  }

  attemptLineAdvance(state) {
    let line = state.currentLine;

    if (line.trigger != null && line.trigger != undefined && line.trigger.type == "line") {
      let nextLine = this.props.script.find(nextLine => {
        return line.trigger.next == nextLine.key;
      });

      state.lines = [
        ...state.lines,
        {name: this.props.giver_name, message: nextLine.message},
      ];
      state.currentLine = nextLine;

      return this.attemptLineAdvance(state);
    } else {
      return state;
    }
  }

  render() {
    let lines = this.state.lines;
    let line = this.state.currentLine;
    let message = this.state.message;

    return (
      <div>
        {lines.map((line, index) => {
          return (
            <p key={index}>
              <b>{line.name}</b> says, "{line.message}"
            </p>
          );
        })}
        <div className="row">
          <div className="col-md-8">
            <input type="text" value={message} className="form-control" onChange={this.handleMessage} onKeyPress={this.handleEnter} />
          </div>
          <div className="col-md-4">
            <a href="#" className="btn btn-primary">Send</a>
          </div>
        </div>
      </div>
    );
  }
}

let Script = {
  Editor: Editor,
  Tester: Tester,
};

export default Script;
