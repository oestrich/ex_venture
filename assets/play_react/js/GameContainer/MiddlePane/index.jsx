import React, { Component } from 'react';
import styled, { css } from 'styled-components';
import RoomInfo from './RoomInfo.jsx';
import RoomEvents from './RoomEvents.jsx';
import PlayerHud from './PlayerHud/index.jsx';
import { theme } from '../../theme.js';

const MiddlePane = () => {
  return (
    <>
      <RoomInfo />
      <RoomEvents />
      <PlayerHud />
    </>
  );
};

export default MiddlePane;
