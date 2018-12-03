import React, { Component } from 'react';
import styled, { css } from 'styled-components';
import RoomInfo from './RoomInfo.jsx';
import RoomEvents from './RoomEvents.jsx';
import PlayerHud from './PlayerHud/index.jsx';
import { theme } from '../../theme.js';

const FlexColumn = styled.div`
  display: flex;
  flex: 0 0 768px;
  flex-direction: column;
  height: 800px;
  background-color: ${theme.bgPrimary};
`;

const MiddlePane = ({ className }) => {
  return (
    <FlexColumn className={className}>
      <RoomInfo />
      <RoomEvents />
      <PlayerHud />
    </FlexColumn>
  );
};

export default MiddlePane;
