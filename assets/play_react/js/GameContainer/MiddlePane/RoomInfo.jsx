import React from 'react';
import styled, { css } from 'styled-components';
import { connect } from 'react-redux';

const RoomInfo = ({ className, roomInfo }) => (
  <div className={className}> RoomInfo {roomInfo} </div>
);

const mapStateToProps = state => {
  return { roomInfo: state.roomInfo };
};

export default connect(mapStateToProps)(styled(RoomInfo)`
  flex: 0 0;
  align-self: stretch;
`);
