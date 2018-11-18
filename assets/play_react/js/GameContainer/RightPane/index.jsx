import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled, { css } from 'styled-components';

const RightPane = ({ className, zoneMap }) => {
  return <div className={className}>RightPane{zoneMap}</div>;
};

const mapStateToProps = state => {
  return {
    zoneMap: state.zoneMap
  };
};

export default connect(mapStateToProps)(styled(RightPane)`
  flex: 1;
`);
