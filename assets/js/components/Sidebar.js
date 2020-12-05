import PropTypes from "prop-types";
import React from "react";

const borderColor = (side) => {
  switch (side) {
    case "bottom":
      return "border-t-2";

    case "left":
      return "border-r-2";

    case "right":
      return "border-l-2";

    case "top":
      return "border-b-2";
  }
};

const Sidebar = ({ children, side, width }) => {
  return (
    <div className={`flex flex-col text-black bg-gray-900 border-teal-900 ${borderColor(side)} ${width}`}>
      {children}
    </div>
  );
};

Sidebar.propTypes = {
  children: PropTypes.node,
  side: PropTypes.string.isRequired,
  width: PropTypes.string,
};

const SidebarSplit = () => {
  return (
    <div className="w-full px-2">
      <div className="border border-teal-900 w-full" />
    </div>
  );
};

export default Sidebar;
export { SidebarSplit };
