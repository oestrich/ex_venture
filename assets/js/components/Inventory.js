import PropTypes from "prop-types";
import React from "react";
import { connect } from "react-redux";

import { getEventsInventory } from "../redux";

import ItemWrapper from "./ItemWrapper";

const Item = ({ itemInstance }) => {
  const attributes = {
    context: "inventory",
    description: itemInstance.item.description,
    id: itemInstance.id,
    name: itemInstance.item.name,
  };

  return (
    <div className="m-2 block bg-gray-800 border border-teal-800 rounded p-4 relative">
      <ItemWrapper attributes={attributes}>
        <span className="text-gray-100">{itemInstance.item.name}</span>
      </ItemWrapper>
    </div>
  );
};

Item.propTypes = {
  itemInstance: PropTypes.shape({
    id: PropTypes.string.isRequired,
    item: PropTypes.shape({
      description: PropTypes.string,
      name: PropTypes.string,
    }),
  }),
};

let Inventory = ({ dispatch, inventory }) => {
  return (
    <div className="flex flex-col overflow-y-scroll">
      <h3 className="text-xl text-gray-200 px-4 pt-4">Inventory</h3>
      <div className="flex-grow overflow-y-scroll">
        {inventory.map((itemInstance) => {
          return <Item key={itemInstance.id} dispatch={dispatch} itemInstance={itemInstance} />;
        })}
      </div>
    </div>
  );
};

Inventory.propTypes = {
  dispatch: PropTypes.func.isRequired,
  inventory: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string.isRequired,
    }),
  ),
};

let mapStateToProps = (state) => {
  const inventory = getEventsInventory(state);

  return { inventory };
};

export default Inventory = connect(mapStateToProps)(Inventory);
