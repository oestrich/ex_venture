import PropTypes from "prop-types";
import React from "react";
import { connect } from "react-redux";

import { getEventsMiniMap, getEventsRoom } from "../redux";

import Coins from "../../static/images/map-icons/coins.svg";
import Drop from "../../static/images/map-icons/drop.svg";
import FamilyHouse from "../../static/images/map-icons/family-house.svg";
import Hammer from "../../static/images/map-icons/hammer.svg";
import PineTree from "../../static/images/map-icons/pine-tree.svg";
import Shop from "../../static/images/map-icons/shop.svg";
import Stein from "../../static/images/map-icons/stein.svg";
import TripleGate from "../../static/images/map-icons/triple-gate.svg";
import Well from "../../static/images/map-icons/well.svg";
import WoodenSign from "../../static/images/map-icons/wooden-sign.svg";

const rows = [2, 1, 0, -1, -2];
const cols = [-2, -1, 0, 1, 2];

let Exits = ({ cell, x }) => {
  const { connections } = cell;

  return (
    <>
      {connections.north && (
        <g className={`cell-exit cell-north ${cell.map_color}`}>
          <rect x={x + 10} y={-15} width={10} height={16} />
          <polyline points={`${x + 10},-15 ${x + 10},1`} />
          <polyline points={`${x + 20},-15 ${x + 20},1`} />
        </g>
      )}
      {connections.south && (
        <g className={`cell-exit cell-south ${cell.map_color}`}>
          <rect x={x + 10} y={29} width={10} height={16} />
          <polyline points={`${x + 10},29 ${x + 10},45`} />
          <polyline points={`${x + 20},29 ${x + 20},45`} />
        </g>
      )}
      {connections.west && (
        <g className={`cell-exit cell-west ${cell.map_color}`}>
          <rect x={x - 15} y={10} width={16} height={10} />
          <polyline points={`${x - 15},10 ${x + 1},10`} />
          <polyline points={`${x - 15},20 ${x + 1},20`} />
        </g>
      )}
      {connections.east && (
        <g className={`cell-exit cell-east ${cell.map_color}`}>
          <rect x={x + 29} y={10} width={16} height={10} />
          <polyline points={`${x + 29},10 ${x + 45},10`} />
          <polyline points={`${x + 29},20 ${x + 45},20`} />
        </g>
      )}
    </>
  );
};

Exits.propTypes = {
  x: PropTypes.number,
  cell: PropTypes.shape({
    map_color: PropTypes.string,
    connections: PropTypes.shape({
      north: PropTypes.string,
      south: PropTypes.string,
      east: PropTypes.string,
      west: PropTypes.string,
    }),
  }),
};

let Icon = ({ name, x, y }) => {
  switch (name) {
    case "coins":
      return <Coins x={x} y={y} width="20" height="20" className="icon" />;

    case "drop":
      return <Drop x={x} y={y} width="20" height="20" className="icon" />;

    case "family-house":
      return <FamilyHouse x={x} y={y} width="20" height="20" className="icon" />;

    case "hammer":
      return <Hammer x={x} y={y} width="20" height="20" className="icon" />;

    case "pine-tree":
      return <PineTree x={x} y={y} width="20" height="20" className="icon" />;

    case "shop":
      return <Shop x={x} y={y} width="20" height="20" className="icon" />;

    case "stein":
      return <Stein x={x} y={y} width="20" height="20" className="icon" />;

    case "triple-gate":
      return <TripleGate x={x} y={y} width="20" height="20" className="icon" />;

    case "well":
      return <Well x={x} y={y} width="20" height="20" className="icon" />;

    case "wooden-sign":
      return <WoodenSign x={x - 1} y={y} width="20" height="20" className="icon" />;
  }

  return null;
};

Icon.propTypes = {
  name: PropTypes.string,
  x: PropTypes.number,
  y: PropTypes.number,
};

let Cell = ({ cell, currentX, currentY, currentZ, x }) => {
  let className = "cell";

  if (cell.x == currentX && cell.y == currentY && cell.z == currentZ) {
    className = `${className} active`;
  }

  className = `${className} ${cell.map_color}`;

  let image = null;

  if (cell.map_icon) {
    image = <Icon x={x + 5} y={5} name={cell.map_icon} />;
  }

  return (
    <g className={className}>
      <path d={`M${x + 5},0 h20 a5,5 0 0 1 5,5 v20 a5,5 0 0 1 -5,5 h-20 a5,5 0 0 1 -5,-5 v-20 a5,5 0 0 1 5,-5 z`} />
      {image}
      <title>{cell.name}</title>
    </g>
  );
};

Cell.propTypes = {
  cell: PropTypes.shape({
    map_color: PropTypes.string,
    map_icon: PropTypes.string,
    name: PropTypes.string,
    x: PropTypes.number,
    y: PropTypes.number,
    z: PropTypes.number,
  }),
  currentX: PropTypes.number,
  currentY: PropTypes.number,
  currentZ: PropTypes.number,
  x: PropTypes.number,
};

const Cells = ({ cells, cellComponent, currentX, currentY, currentZ }) => {
  return rows.map((row) => {
    const y = 20 + (-1 * row + 2) * 60; // eslint-disable-line no-mixed-operators

    return (
      <g key={row} transform={`translate(0, ${y})`}>
        {cols.map((col) => {
          const x = 20 + (col + 2) * 60; // eslint-disable-line no-mixed-operators

          const cell = cells.find((cell) => {
            return cell.x == col + currentX && cell.y == row + currentY && cell.z == currentZ;
          });

          if (!cell) {
            return null;
          }

          const CustomTag = cellComponent;

          return <CustomTag key={x} cell={cell} currentX={currentX} currentY={currentY} currentZ={currentZ} x={x} />;
        })}
      </g>
    );
  });
};

let Map = ({ cells, room }) => {
  if (room === null) {
    return null;
  }

  const currentX = room.x;
  const currentY = room.y;
  const currentZ = room.z;

  return (
    <div className="flex flex-col items-center" style={{ height: 310 }}>
      <svg className="h-full" style={{ width: 310 }} version="1.1" xmlns="http://www.w3.org/2000/svg">
        <Cells cells={cells} currentX={currentX} currentY={currentY} currentZ={currentZ} cellComponent={Cell} />
        <Cells cells={cells} currentX={currentX} currentY={currentY} currentZ={currentZ} cellComponent={Exits} />
      </svg>
    </div>
  );
};

Map.propTypes = {
  cells: PropTypes.arrayOf(
    PropTypes.shape({
      connections: PropTypes.shape({
        north: PropTypes.string,
        south: PropTypes.string,
        east: PropTypes.string,
        west: PropTypes.string,
      }),
    }),
  ),
  room: PropTypes.shape({
    x: PropTypes.number,
    y: PropTypes.number,
    z: PropTypes.number,
  }),
};

let mapStateToProps = (state) => {
  const mini_map = getEventsMiniMap(state);
  const room = getEventsRoom(state);

  return { cells: mini_map, room };
};

export default connect(mapStateToProps)(Map);
