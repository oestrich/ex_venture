import React from 'react';
import OverworldMap from "./overworld";
import debounceEvent from "./debounce";
import _ from "lodash";

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
      <div className="row">
        <div className="col-md-6">
          <label>Exits</label>
          <select className="form-control" value={selectedRoomId} onChange={exitOnChange}>
            <option value={-1}>Select a room</option>
            <option value={-2}>Delete Exit</option>
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
        </div>
        <div className="col-md-6">
          <label>Direction</label>
          <select className="form-control" value={selectedDirection} onChange={directionOnChange}>
            {directions.map(direction => {
              return (
                <option key={direction} value={direction}>{direction}</option>
              );
            })}
          </select>
        </div>
      </div>
    );
  }
}

class MapCell extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      hover: false,
    };

    this.onMouseClick = this.onMouseClick.bind(this);
    this.onMouseEnter = this.onMouseEnter.bind(this);
    this.onMouseLeave = this.onMouseLeave.bind(this);
  }

  shouldComponentUpdate(nextProps, nextState) {
    if (this.state.hover != nextState.hover) {
      return true;
    }

    if (this.state.exits != nextState.exits) {
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
    if (this.props.roomId == -1) { return; }

    let startId = {x: this.props.x, y: this.props.y};

    if (this.props.roomId == -2) {
      this.props.deleteExit(this.props.direction, startId);
    } else {
      this.props.addExit(this.props.direction, startId, this.props.roomId);
    }
  }

  render() {
    let color = this.props.color;
    let symbol = this.props.symbol;

    symbol = symbol == " " ? "\xa0" : symbol;

    let tooltip = this.props.exits.length > 0 ? "hover-tooltip" : "";
    let direction = this.props.direction;
    let hoverClass = this.state.hover ? `hover hover-${direction} ${tooltip}` : "";
    let exitClasses = _.map(this.props.exits, exit => { return exit.direction; }).join(" ");

    return (
      <span
        onMouseDown={this.onMouseClick}
        onMouseEnter={this.onMouseEnter}
        onMouseLeave={this.onMouseLeave}
        data-exits={exitClasses}
        className={`color-code-${color} ${hoverClass} ${exitClasses}`}>
        {symbol}
      </span>
    );
  }
}

export default class WorldMapExits extends React.Component {
  constructor(props) {
    super(props);

    let json = JSON.parse(document.getElementById("map-data").dataset.map);
    let map = new OverworldMap(json);

    this.state = {
      map: map,
      selectedRoomId: -1,
      selectedDirection: "north",
      exits: this.parseExits(props.exits),
    };

    this.addExit = this.addExit.bind(this);
    this.deleteExit = this.deleteExit.bind(this);
    this.directionChange = this.directionChange.bind(this);
    this.roomIdChange = this.roomIdChange.bind(this);
  }

  parseExits(exits) {
    return exits.map(exit => {
      return this.parseExit(exit);
    });
  }

  parseExit(exit) {
    let segments = exit.start_overworld_id.split(":");
    let coords = segments[2].split(",");
    exit.start_id = {x: coords[0], y: coords[1]};
    return exit;
  }

  roomIdChange(roomId) {
    this.setState({selectedRoomId: roomId});
  }

  directionChange(direction) {
    this.setState({selectedDirection: direction});
  }

  addExit(direction, startCell, finishId) {
    let exit = {direction: direction, start_overworld: startCell, finish_room_id: finishId}

    let state = this.state;
    let setState = this.setState.bind(this);

    let csrfToken = document.querySelector("meta[name='csrf-token']");

    fetch(this.props.exit_path, {
      method: "POST",
      body: JSON.stringify({exit: exit}),
      headers: {
        'x-csrf-token': csrfToken.content,
        'content-type': 'application/json',
        'accept': 'application/json',
      },
      credentials: 'same-origin',
    }).then(function(response) {
      return response.json();
    }).then(response => {
      if (response.ok) {
        let exits = state.exits;
        exits.push(this.parseExit(response));
        setState({exits});
      }
    });
  }

  deleteExit(direction, startId) {
    let exit = _.find(this.state.exits, exit => {
      return exit.direction == direction && exit.start_id.x == startId.x && exit.start_id.y == startId.y;
    });

    if (exit) {
      let csrfToken = document.querySelector("meta[name='csrf-token']");

      fetch(`${this.props.exit_path}/${exit.id}`, {
        method: "delete",
        headers: {
          'x-csrf-token': csrfToken.content,
          'accept': 'application/json',
        },
        credentials: 'same-origin',
      }).then(response => {
        let exitId = exit.id;
        let exits = _.reject(this.state.exits, exit => {
          return exit.id == exitId;
        });
        this.setState({exits});
      });
    }
  }

  render() {
    let map = this.state.map;
    let roomId = this.state.selectedRoomId;
    let direction = this.state.selectedDirection;
    let exits = this.state.exits;

    let addExit = this.addExit;
    let deleteExit = this.deleteExit;

    return (
      <div>
        <ExitSelector
          directions={this.props.directions}
          exits={this.props.room_exits}
          roomId={roomId}
          roomIdChange={this.roomIdChange}
          direction={direction}
          directionChange={this.directionChange} />

        <div className="world-map exits terminal">
          {map.rows((row, y) => {
            return (
              <div key={y}>
                {row.map((cell, x) => {
                  let cellExits = _.filter(exits, exit => {
                    return exit.start_id.x == x && exit.start_id.y == y;
                  });

                  return (
                    <MapCell
                      key={x}
                      id={cell.id}
                      x={x} y={y}
                      exits={cellExits}
                      addExit={addExit}
                      deleteExit={deleteExit}
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
