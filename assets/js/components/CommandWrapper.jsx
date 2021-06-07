import PropTypes from "prop-types";
import React from "react";
import { connect } from "react-redux";

import { Creators, Tooltip } from "../kalevala";

let CommandWrapper = ({ children, dispatch, send }) => {
  const onClick = () => {
    dispatch(
      Creators.socketSendEvent({
        topic: "system/send",
        data: {
          text: send,
        },
      }),
    );
  };

  return (
    <Tooltip tip={`Send "${send}"`}>
      <span className="underline cursor-pointer" onClick={onClick}>
        {children}
      </span>
    </Tooltip>
  );
};

CommandWrapper.propTypes = {
  children: PropTypes.node,
  dispatch: PropTypes.func.isRequired,
  send: PropTypes.string.isRequired,
};

CommandWrapper = connect()(CommandWrapper);
export default CommandWrapper;
