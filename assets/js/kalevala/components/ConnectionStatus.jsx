import PropTypes from "prop-types";
import React from "react";
import { connect } from "react-redux";

import { getSocketConnectionState } from "../redux";

class ConnectionStatus extends React.Component {
  connectionClassName() {
    if (this.props.connected) {
      return "bg-teal-500";
    } else {
      return "bg-red-500";
    }
  }

  connectionTitle() {
    if (this.props.connected) {
      return "Connected";
    } else {
      return "Disconnected";
    }
  }

  render() {
    return (
      <div className="flex items-center justify-center">
        <div className={`rounded-full w-4 h-4 ${this.connectionClassName()}`} title={this.connectionTitle()} />
      </div>
    );
  }
}

ConnectionStatus.propTypes = {
  connected: PropTypes.bool.isRequired,
};

let mapStateToProps = (state) => {
  const connected = getSocketConnectionState(state);
  return { connected };
};

export default connect(mapStateToProps)(ConnectionStatus);
