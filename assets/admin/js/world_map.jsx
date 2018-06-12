import React from 'react';
import OverworldMap from "./overworld";
import debounceEvent from "./debounce";

if (process.env.NODE_ENV !== 'production') {
  const {whyDidYouUpdate} = require('why-did-you-update');
  whyDidYouUpdate(React);
}

class Colors extends React.PureComponent {
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

class Symbols extends React.PureComponent {
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

    this.handleClick = this.handleClick.bind(this);
    this.onMouseDown = this.onMouseDown.bind(this);
    this.onMouseUp = this.onMouseUp.bind(this);
    this.onMouseEnter = debounceEvent(this.onMouseEnter.bind(this), 5);
    this.onMouseLeave = debounceEvent(this.onMouseLeave.bind(this), 5);
  }

  shouldComponentUpdate(nextProps, nextState) {
    if (this.state.hover != nextState.hover) {
      return true;
    }

    return this.props.color != nextProps.color && this.props.symbol != nextProps.symbol;
  }

  handleClick(event) {
    this.props.handleClick(this.props.x, this.props.y);
  }

  onMouseDown(event) {
    this.props.onMouseDown(event);
  }

  onMouseUp(event) {
    this.props.onMouseUp(event);
  }

  onMouseEnter(event) {
    this.setState({hover: true});
    this.props.onMouseEnter(this.props.x, this.props.y);
  }

  onMouseLeave(event) {
    if (!this.props.drag) {
      this.setState({hover: false});
    }
  }

  render() {
    let color = this.state.hover ? this.props.selectedColor : this.props.color;
    let symbol = this.state.hover ? this.props.selectedSymbol : this.props.symbol;

    symbol = symbol == " " ? "\xa0" : symbol;

    let handleClick = this.handleClick;
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

export default class WorldMap extends React.Component {
  constructor(props) {
    super(props);

    let json = JSON.parse(document.getElementById("map-data").dataset.map);
    let map = new OverworldMap(json);

    this.state = {
      drag: false,
      map: map,
      selectedSymbol: "%",
      selectedColor: "white",
    };

    this.handleClick = this.handleClick.bind(this);
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
    this.state.map.updateCell(x, y, {s: this.state.selectedSymbol, c: this.state.selectedColor});
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
    let drag = this.state.drag;
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
          {map.rows((row, y) => {
            return (
              <div key={y}>
                {row.map((cell, x) => {
                  return (
                    <MapCell
                      key={x}
                      x={x}
                      y={y}
                      drag={drag}
                      symbol={cell.s}
                      color={cell.c}
                      onMouseDown={this.onMouseDown}
                      onMouseUp={this.onMouseUp}
                      onMouseEnter={this.onMouseEnter}
                      handleClick={this.handleClick}
                      selectedSymbol={selectedSymbol}
                      selectedColor={selectedColor} />
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
