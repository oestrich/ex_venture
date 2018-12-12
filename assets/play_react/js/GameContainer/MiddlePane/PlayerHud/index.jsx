import React from 'react';
import styled from 'styled-components';
import ActionBar from './ActionBar.jsx';
import StatusBar from './StatusBar.jsx';
import InputBar from './InputBar.jsx';

const HudContainer = styled.div`
  padding: 1em 2em 1em 2em;
`;

const PlayerHud = () => {
  return (
    <HudContainer>
      <ActionBar />
      <StatusBar />
      <InputBar />
    </HudContainer>
  );
};

export default PlayerHud;
