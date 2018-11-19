import React from 'react';
import { connect } from 'react-redux';
import styled, { css } from 'styled-components';

const RoomEvents = ({ className, eventStream }) => {
  return (
    <div className={className}>
      RoomEvents
      <div>
        {eventStream.map(event => {
          return (
            <div>
              <div>{event}</div>
              <br />
            </div>
          );
        })}
      </div>
    </div>
  );
};

RoomEvents.defaultProps = {
  eventStream: []
};

const mapStateToProps = state => {
  return { eventStream: state.eventStream };
};

export default connect(mapStateToProps)(styled(RoomEvents)`
  height: 100%;
  overflow: scroll;
`);
