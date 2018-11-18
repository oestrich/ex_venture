import React from 'react';
import { connect } from 'react-redux';
import styled, { css } from 'styled-components';

const RoomEvents = ({ className, eventStream }) => {
  return (
    <div className={className}>
      RoomEvents
      {eventStream.map(event => {
        return <div>{event}</div>;
      })}
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
  flex: 0 0;
  align-self: stretch;
`);
