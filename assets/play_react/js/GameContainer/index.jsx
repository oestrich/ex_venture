import React, { Component } from 'react';
import styled from 'styled-components';
import LeftPane from './LeftPane/index.jsx';
import MiddlePane from './MiddlePane/index.jsx';
import RightPane from './RightPane/index.jsx';
import { theme } from '../theme.js';

const FlexRow = styled.div`
  display: flex;
  flex-direction: row;
  height: 800px;
  widht: 100%;
  color: ${theme.text};
  font-family: Lucida Grande, Lucida Sans Unicode, Lucida Sans, Geneva, Verdana,
    sans-serif;
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