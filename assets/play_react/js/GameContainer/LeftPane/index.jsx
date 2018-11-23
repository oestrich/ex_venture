import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled, { css } from 'styled-components';

// TODO: Long string will not create newlines, it will increase container size
const LeftPane = ({ className, characterInfo, characterVitals }) => {
  const vitals = characterVitals ? JSON.parse(characterVitals) : {};
  const charInfo = characterInfo ? JSON.parse(characterInfo) : {};
  return (
    <div className={className}>
      LeftPane
      {Object.keys(charInfo).map(key => {
        <div key={key}>
          {key}: {vitals[key]}
        </div>;
      })}{' '}
      *{' '}
      {Object.keys(vitals).map(key => {
        return (
          <div key={key}>
            {key}: {vitals[key]}
          </div>
        );
      })}
    </div>
  );
};

const mapStateToProps = state => {
  return {
    characterInfo: state.characterInfo,
    characterVitals: state.characterVitals
  };
};

LeftPane.defaultProps = { characterVitals: '{}', characterInfo: '{}' };

export default connect(mapStateToProps)(styled(LeftPane)`
  padding: 1em 1em 1em 1em;
  flex: 1;
  background-color: #435aaf;
`);
