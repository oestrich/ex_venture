import React, { Component } from 'react';
import styled, { css } from 'styled-components';
import RoomInfo from './RoomInfo.jsx';
import RoomEvents from './RoomEvents.jsx';
import PlayerHud from './PlayerHud/index.jsx';

const FlexColumn = styled.div`
  display: flex;
  flex-direction: column;
  height: 800px;
`;

const RoomContainer = styled.div`
  display: flex;
  flex-direction: column;
  flex: 0 0 90%;
`;

const MiddlePane = ({ className }) => {
  return (
    <FlexColumn className={className}>
      <RoomContainer>
        <RoomInfo />
        <RoomEvents />
      </RoomContainer>
      <PlayerHud />
    </FlexColumn>
  );
};

export default styled(MiddlePane)`
  flex: 0 0 768px;
`;
