import React, { Component } from 'react';
import styled, { css } from 'styled-components';
import LeftPane from './LeftPane.jsx';
import MiddlePane from './MiddlePane.jsx';
import RightPane from './RightPane.jsx';

const FlexRow = styled.div`
  display: flex;
  flex-direction: row;
  height: 800px;
`;

const GameContainer = props => {
  return (
    <FlexRow>
      <LeftPane />
      <MiddlePane />
      <RightPane />
    </FlexRow>
  );
};

export default GameContainer;
