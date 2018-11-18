import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled, { css } from 'styled-components';

const LeftPane = ({ className, characterInfo, characterVitals }) => {
  return (
    <div className={className}>
      LeftPane{characterInfo} * {characterVitals}
    </div>
  );
};

const mapStateToProps = state => {
  return {
    characterInfo: state.characterInfo,
    characterVitals: state.characterVitals
  };
};

export default connect(mapStateToProps)(styled(LeftPane)`
  flex: 1;
`);
