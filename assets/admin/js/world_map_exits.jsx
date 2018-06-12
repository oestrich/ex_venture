import React from 'react';
import OverworldMap from "./overworld";
import debounceEvent from "./debounce";

class ExitSelector extends React.PureComponent {
  constructor(props) {
    super(props);

    this.directionOnChange = this.directionOnChange.bind(this);
    this.exitOnChange = this.exitOnChange.bind(this);
  }

  directionOnChange(event) {
    this.props.directionChange(event.target.value);
  }

  exitOnChange(event) {
    this.props.roomIdChange(event.target.value);
  }

  render() {
    let selectedRoomId = this.props.roomId;
    let selectedDirection = this.props.direction;

    let exits = this.props.exits;
    let directions = this.props.directions;

    let directionOnChange = this.directionOnChange;
    let exitOnChange = this.exitOnChange;

    return (
      <div>
        <label>Exits</label>
        <select value={selectedRoomId} onChange={exitOnChange}>
          <option value={-1}>Select a room</option>
          {exits.map(zone => {
            return (
              <optgroup key={zone.name} label={zone.name}>
                {zone.rooms.map(room => {
                  return (
                    <option key={room.id} value={room.id}>{room.name}</option>
                  );
                })}
              </optgroup>
            );
          })}
        </select>

        <label>Direction</label>
        <select value={selectedDirection} onChange={directionOnChange}>
          {directions.map(direction => {
            return (
              <option key={direction} value={direction}>{direction}</option>
            );
          })}
        </select>
      </div>
    );
  }
}

class MapCell extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      hover: false,
      exitClasses: [],
    };

    this.onMouseClick = this.onMouseClick.bind(this);
    this.onMouseEnter = this.onMouseEnter.bind(this);
    this.onMouseLeave = this.onMouseLeave.bind(this);
  }

  shouldComponentUpdate(nextProps, nextState) {
    if (this.state.hover != nextState.hover) {
      return true;
    }

    if (this.state.exitClasses != nextState.exitClasses) {
      return true;
    }

    return false;
  }

  isEmpty() {
    return this.props.symbol == " " && this.props.color == null;
  }

  onMouseEnter(event) {
    if (this.isEmpty()) { return; }
    this.setState({hover: true});
  }

  onMouseLeave(event) {
    this.setState({hover: false});
  }

  onMouseClick(event) {
    console.log(this.props);
    if (this.props.roomId == -1) { return; }
    let exitClasses = this.state.exitClasses;
    exitClasses.push(this.props.direction);
    this.setState({exitClasses});

    let startId = {x: this.props.x, y: this.props.y};
    this.props.addExit(this.props.direction, startId, this.props.roomId);
  }

  render() {
    let color = this.props.color;
    let symbol = this.props.symbol;

    symbol = symbol == " " ? "\xa0" : symbol;

    let direction = this.props.direction;
    let hoverClass = this.state.hover ? `hover hover-${direction}` : "";
    let exitClasses = this.state.exitClasses.join(" ");

    return (
      <span
        onMouseDown={this.onMouseClick}
        onMouseEnter={this.onMouseEnter}
        onMouseLeave={this.onMouseLeave}
        className={`color-code-${color} ${hoverClass} ${exitClasses}`}>
        {symbol}
      </span>
    );
  }
}

export default class WorldMapExits extends React.Component {
  constructor(props) {
    super(props);

    let map = new OverworldMap(this.props.map);

    this.state = {
      map: map,
      selectedRoomId: -1,
      selectedDirection: "north",
    };

    this.addExit = this.addExit.bind(this);
    this.directionChange = this.directionChange.bind(this);
    this.roomIdChange = this.roomIdChange.bind(this);
  }

  roomIdChange(roomId) {
    this.setState({selectedRoomId: roomId});
  }

  directionChange(direction) {
    this.setState({selectedDirection: direction});
  }

  addExit(direction, startId, finishId) {
    console.log(direction, startId, finishId);
  }

  render() {
    let map = this.state.map;
    let roomId = this.state.selectedRoomId;
    let direction = this.state.selectedDirection;

    let addExit = this.addExit;

    return (
      <div>
        <ExitSelector
          directions={this.props.directions}
          exits={this.props.exits}
          roomId={roomId}
          roomIdChange={this.roomIdChange}
          direction={direction}
          directionChange={this.directionChange} />

        <div className="world-map exits terminal">
          {map.rows((row, y) => {
            return (
              <div key={y}>
                {row.map((cell, x) => {
                  return (
                    <MapCell
                      key={x}
                      x={x} y={y}
                      addExit={addExit}
                      symbol={cell.s}
                      color={cell.c}
                      direction={direction}
                      roomId={roomId} />
                  );
                })}
              </div>
            );
          })}
        </div>
      </div>
    );
  }
}
