import React, { Component } from 'react';
import styled from 'styled-components';
import LeftPane from './LeftPane/index.jsx';
import MiddlePane from './MiddlePane/index.jsx';
import RightPane from './RightPane/index.jsx';
import MediaQuery from 'react-responsive';
import { theme } from '../theme.js';

const FlexRow = styled.div`
  display: flex;
  flex-direction: row;
  height: 800px;
  widht: 100%;
  font-family: ${theme.font};
`;

const LeftPaneContainer = styled.div`
  padding: 2em 2em 2em 2em;
  flex: 1;
`;

const MiddlePaneContainer = styled.div`
  display: flex;
  flex: 0 0 768px;
  flex-direction: column;
  height: 800px;
`;

const RightPaneContainer = styled.div`
  padding: 2em 2em 2em 2em;
  flex: 1;
`;

const GameContainer = props => {
  return (
    <FlexRow>
      <MediaQuery minWidth={768}>
        {matches => {
          return matches ? (
            <LeftPaneContainer className="character-info">
              <LeftPane />
            </LeftPaneContainer>
          ) : null;
        }}
      </MediaQuery>

      <MiddlePaneContainer>
        <MiddlePane className="body" />
      </MiddlePaneContainer>

      <MediaQuery minWidth={768}>
        {matches => {
          return matches ? (
            <RightPaneContainer className="room-info">
              <RightPane />
            </RightPaneContainer>
          ) : null;
        }}
      </MediaQuery>
    </FlexRow>
  );
};

export default GameContainer;
