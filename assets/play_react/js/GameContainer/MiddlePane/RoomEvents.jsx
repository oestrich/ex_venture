import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled, { css } from 'styled-components';
import VmlToJsx from '../../SharedComponents/VmlToJsx.jsx';

class RoomEvents extends Component {
  constructor(props) {
    super(props);
    this.scrollToBottom = this.scrollToBottom.bind(this);
  }
  scrollToBottom() {
    this.messagesEnd.scrollIntoView({ behavior: 'smooth' });
  }

  componentDidMount() {
    this.scrollToBottom();
  }

  componentDidUpdate() {
    this.scrollToBottom();
  }
  render() {
    return (
      <div className={this.props.className}>
        <div>
          {this.props.eventStream.map(event => {
            return (
              <div key={event.sent_at}>
                <VmlToJsx vmlString={event.message} />
                <br />
                <br />
              </div>
            );
          })}
          <div
            ref={el => {
              this.messagesEnd = el;
            }}
          />
        </div>
      </div>
    );
  }
}

const mapStateToProps = ({ eventStream }) => {
  return { eventStream };
};

export default connect(mapStateToProps)(styled(RoomEvents)`
  padding: 1em 2em 1em 2em;
  height: 100%;
  overflow-y: scroll;
`);
