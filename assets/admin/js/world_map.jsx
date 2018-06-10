import React from 'react';

const debounceEvent = (callback, time) => {
  let interval;
  return (...args) => {
    clearTimeout(interval);
    interval = setTimeout(() => {
      interval = null;
      callback(...args);
    }, time);
  };
};

class Colors extends React.Component {
  constructor(props) {
    super(props);

    this.changeColor = this.changeColor.bind(this);
  }

  buttonClassName(symbol) {
    if (symbol == this.props.selectedColor) {
      return "btn btn-primary";
    } else {
      return "btn btn-default";
    }
  }

  changeColor(color) {
    let handleColorChange = this.props.handleColorChange;

    return (event) => {
      event.preventDefault();
      handleColorChange(color);
    };
  }

  render() {
    let colors = this.props.colors;
    let changeColor = this.changeColor;

    return (
      <div>
        {colors.map((color, index) => {
          return (
            <button key={index} onClick={changeColor(color)} className={this.buttonClassName(color)}>{color}</button>
          );
        })}
      </div>
    );
  }
}

class Symbols extends React.Component {
  constructor(props) {
    super(props);
    this.symbols = [
      "~", "!", "$", "%", "^", "&", "|", "*", ".", ";", "#",
      ",", "_", "-", "[", "]", "{", "}", "\\", "/", "<", ">",
    ];
    this.changeSymbol = this.changeSymbol.bind(this);
  }

  buttonClassName(symbol) {
    if (symbol == this.props.selectedSymbol) {
      return "btn btn-primary";
    } else {
      return "btn btn-default";
    }
  }

  changeSymbol(symbol) {
    let handleSymbolChange = this.props.handleSymbolChange;

    return (event) => {
      event.preventDefault();
      handleSymbolChange(symbol);
    };
  }

  render() {
    let symbols = this.symbols;
    let changeSymbol = this.changeSymbol;

    return (
      <div>
        {symbols.map((symbol, index) => {
          return (
            <button key={index} onClick={changeSymbol(symbol)} className={this.buttonClassName(symbol)}>{symbol}</button>
          );
        })}
      </div>
    );
  }
}

class MapCell extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      hover: false,
    }

    this.onMouseDown = this.onMouseDown.bind(this);
    this.onMouseUp = this.onMouseUp.bind(this);
    this.onMouseEnter = debounceEvent(this.onMouseEnter.bind(this), 10);
    this.onMouseLeave = debounceEvent(this.onMouseLeave.bind(this), 10);
  }

  onMouseDown(event) {
    this.props.onMouseDown(event);
  }

  onMouseUp(event) {
    this.props.onMouseUp(event);
  }

  onMouseEnter(event) {
    this.setState({hover: true});
    this.props.onMouseEnter(event);
  }

  onMouseLeave(event) {
    this.setState({hover: false});
  }

  render() {
    let color = this.state.hover ? this.props.selectedColor : this.props.color;
    let symbol = this.state.hover ? this.props.selectedSymbol : this.props.symbol;

    symbol = symbol == " " ? "\xa0" : symbol;

    let handleClick = this.props.handleClick;
    let handleDrag = this.handleDrag;

    return (
      <span
        className={`color-code-${color}`}
        onClick={handleClick}
        onMouseDown={this.onMouseDown}
        onMouseUp={this.onMouseUp}
        onMouseEnter={this.onMouseEnter}
        onMouseLeave={this.onMouseLeave} >
        {symbol}
      </span>
    );
  }
}

class MapRow extends React.Component {
  constructor(props) {
    super(props);

    this.onMouseEnter = this.onMouseEnter.bind(this);
  }

  onMouseEnter(index) {
    this.props.onMouseEnter(index);
  }

  render() {
    let row = this.props.row;
    let selectedSymbol = this.props.selectedSymbol;
    let selectedColor = this.props.selectedColor;

    let handleClick = this.props.handleClick;
    let onMouseEnter = this.onMouseEnter;

    return (
      <div>
        {row.map((cell, index) => {
          let cellHandleClick = (event) => {
            handleClick(index);
          }

          let cellOnMouseEnter = (event) => {
            onMouseEnter(index);
          }

          return (
            <MapCell
              key={index}
              symbol={cell.s}
              color={cell.c}
              onMouseDown={this.props.onMouseDown}
              onMouseUp={this.props.onMouseUp}
              onMouseEnter={cellOnMouseEnter}
              handleClick={cellHandleClick}
              selectedSymbol={selectedSymbol}
              selectedColor={selectedColor} />
          );
        })}
      </div>
    );
  }
}

/**
 * Map helper functions
 */
class OverworldMap {
  constructor(map) {
    let groupedMap = map.reduce((acc, val) => {
      if (acc[val.y] == undefined) {
        acc[val.y] = [];
      }

      acc[val.y].push(val);

      return acc;
    }, []);

    this.overworld = groupedMap.map((row) => {
      return row.sort((a, b) => { return a.x - b.x; });
    });
  }

  updateCell(x, y, attrs) {
    this.overworld[y][x].s = attrs.s;
    this.overworld[y][x].c = attrs.c;
  }

  rows(fun) {
    return this.overworld.map(fun);
  }

  toJSON() {
    let flattenedMap = this.overworld.reduce((acc, val) => acc.concat(val), []);
    return JSON.stringify(flattenedMap);
  }
}

export default class WorldMap extends React.Component {
  constructor(props) {
    super(props);

    let map = new OverworldMap(this.props.map);

    this.state = {
      drag: false,
      map: map,
      selectedSymbol: "%",
      selectedColor: "white",
    };

    this.handleColorChange = this.handleColorChange.bind(this);
    this.handleSymbolChange = this.handleSymbolChange.bind(this);
    this.onMouseDown = this.onMouseDown.bind(this);
    this.onMouseEnter = this.onMouseEnter.bind(this);
    this.onMouseUp = this.onMouseUp.bind(this);
  }

  handleColorChange(color) {
    this.setState({selectedColor: color});
  }

  handleSymbolChange(symbol) {
    this.setState({selectedSymbol: symbol});
  }

  handleClick(x, y) {
    let map = this.state.map;

    map.updateCell(x, y, {s: this.state.selectedSymbol, c: this.state.selectedColor});

    this.setState({map});
  }

  onMouseDown(event) {
    this.setState({drag: true});
  }

  onMouseEnter(x, y) {
    if (this.state.drag) {
      this.handleClick(x, y);
    }
  }

  onMouseUp(event) {
    this.setState({drag: false});
  }

  render() {
    let map = this.state.map;
    let selectedSymbol = this.state.selectedSymbol;
    let selectedColor = this.state.selectedColor;

    return (
      <div>
        <input type="hidden" name="zone[overworld_map]" value={map.toJSON()} />
        <input type="submit" className="btn btn-primary pull-right" value="Save" />

        <Colors colors={this.props.colors} handleColorChange={this.handleColorChange} selectedColor={selectedColor} />
        <Symbols handleSymbolChange={this.handleSymbolChange} selectedSymbol={selectedSymbol} />

        <div className="world-map terminal">
          {map.rows((row, index) => {
            let rowHandleClick = (x) => {
              this.handleClick(x, index);
            };

            let rowOnMouseEnter = (x) => {
              this.onMouseEnter(x, index);
            };

            return (
              <MapRow
                key={index}
                row={row}
                onMouseDown={this.onMouseDown}
                onMouseEnter={rowOnMouseEnter}
                onMouseUp={this.onMouseUp}
                handleClick={rowHandleClick}
                selectedSymbol={selectedSymbol}
                selectedColor={selectedColor} />
            );
          })}
        </div>
      </div>
    );
  }
}
