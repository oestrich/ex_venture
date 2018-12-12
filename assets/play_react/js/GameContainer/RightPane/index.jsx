import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled from 'styled-components';
import { theme } from '../../theme.js';

const RightPane = ({ zoneMap }) => {
  return <>{zoneMap}</>;
};

const mapStateToProps = state => {
  return {
    zoneMap: state.zoneMap
  };
};

export default connect(mapStateToProps)(RightPane);
