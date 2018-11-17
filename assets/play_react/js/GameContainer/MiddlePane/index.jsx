import React, { Component } from 'react';
import styled, { css } from 'styled-components';
import RoomInfo from './RoomInfo.jsx';
import RoomEvents from './RoomEvents.jsx';
import PlayerHud from './PlayerHud/index.jsx';

const MiddlePane = ({ className }) => {
  return (
    <div className={className}>
      <RoomInfo />
      <RoomEvents />
      <PlayerHud />
    </div>
  );
};

export default styled(MiddlePane)`
  flex: 0 0 768px;
`;
