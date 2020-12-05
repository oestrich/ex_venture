import PropTypes from "prop-types";
import React from "react";
import { connect } from "react-redux";

import { getChannelMessages } from "../redux";

const Message = ({ channelName, character, text }) => {
  return (
    <span className="block bg-gray-800 border border-teal-800 rounded p-4 m-2">
      <div className="block text-gray-200">
        <span className="text-gray-500">[{channelName}]</span> <span className="text-yellow-600">{character.name}</span>{" "}
        says,
      </div>
      <span className="text-green-500">{text}</span>
    </span>
  );
};

Message.propTypes = {
  channelName: PropTypes.string.isRequired,
  character: PropTypes.shape({
    name: PropTypes.string.isRequired,
  }).isRequired,
  text: PropTypes.string.isRequired,
};

class Channels extends React.Component {
  constructor(props) {
    super(props);

    this.triggerScroll = true;
  }

  componentDidMount() {
    this.scrollToBottom();
  }

  componentDidUpdate() {
    this.scrollToBottom();
  }

  getSnapshotBeforeUpdate() {
    let visibleBottom = this.messages.scrollTop + this.messages.clientHeight;
    this.triggerScroll = !(visibleBottom + 250 < this.messages.scrollHeight);

    return null;
  }

  scrollToBottom() {
    if (this.triggerScroll) {
      this.el.scrollIntoView();
    }
  }

  render() {
    const { messages } = this.props;

    return (
      <div className="flex flex-col overflow-y-scroll">
        <h3 className="text-xl text-gray-200 p-4">Communications</h3>
        <div
          className="flex-grow overflow-y-scroll"
          ref={(el) => {
            this.messages = el;
          }}
        >
          {messages.map(({ channelName, character, id, text }) => {
            return <Message key={id} channelName={channelName} character={character} text={text} />;
          })}
          <div
            ref={(el) => {
              this.el = el;
            }}
          />
        </div>
      </div>
    );
  }
}

Channels.propTypes = {
  messages: PropTypes.arrayOf(
    PropTypes.shape({
      channelName: PropTypes.string.isRequired,
      character: PropTypes.object,
      id: PropTypes.string.isRequired,
      text: PropTypes.string.isRequired,
    }),
  ),
};

let mapStateToProps = (state) => {
  const messages = getChannelMessages(state);

  return { messages };
};

export default connect(mapStateToProps)(Channels);
