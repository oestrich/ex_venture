import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled, { css } from 'styled-components';
import { theme } from '../../theme.js';

const RightPane = ({ className, zoneMap }) => {
  return <div className={className}>RightPane{zoneMap}</div>;
};

const mapStateToProps = state => {
  return {
    zoneMap: state.zoneMap
  };
};

export default connect(mapStateToProps)(styled(RightPane)`
  padding: 2em 2em 2em 2em;
  flex: 1;
  background-color: ${theme.bgSecondary};
`);
