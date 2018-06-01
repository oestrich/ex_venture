import React from 'react';

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

  render() {
    let key = this.state.key;
    let message = this.state.message;
    let trigger = this.state.trigger || "none";
    let unknown = this.state.unknown || "";
    let listeners = this.state.listeners;

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
            </select>
          </div>
        </div>
        <div className="row">
          <div className="col-md-12">
            <label>Message</label>
            <textarea value={message} className="form-control" onChange={this.handleUpdateField("message")} />
          </div>
        </div>
        <div className="row">
          <div className="col-md-12">
            <label>Unknown Response</label>
            <textarea value={unknown} className="form-control" onChange={this.handleUpdateField("unknown")} />
          </div>
        </div>
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
      </div>
    );
  }
}

export default class Script extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      lines: props.lines,
    }

    this.handleUpdate = this.handleUpdate.bind(this);
    this.addLine = this.addLine.bind(this);
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
      unknown: null,
      listeners: [],
    };

    let lines = this.state.lines;

    this.setState({
      lines: [...lines, line],
    });
  }

  render() {
    let lines = this.state.lines;
    let handleUpdate = this.handleUpdate;

    let scriptJSON = JSON.stringify(this.state.lines);

    return (
      <div className="form-group">
        <input type="hidden" name={this.props.name} value={scriptJSON} />

        <label className="col-md-4">Script</label>
        <div className="col-md-8">
          {lines.map((line, index) => {
            return (
              <div key={index}>
                <Line line={line} index={index} handleUpdate={handleUpdate} />
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
