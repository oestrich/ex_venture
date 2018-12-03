import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled from 'styled-components';
import { theme } from '../../theme.js';

const RightPaneContainer = styled.div`
  padding: 2em 2em 2em 2em;
  flex: 1;
  background-color: ${theme.bgSecondary};
`;

const RightPane = ({ className, zoneMap }) => {
  return (
    <RightPaneContainer className={className}>{zoneMap}</RightPaneContainer>
  );
};

const mapStateToProps = state => {
  return {
    zoneMap: state.zoneMap
  };
};

export default connect(mapStateToProps)(RightPane);
