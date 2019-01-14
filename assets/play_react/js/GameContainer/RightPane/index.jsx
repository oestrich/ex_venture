import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled from 'styled-components';
import { theme } from '../../theme.js';
import VmlParser from '../../SharedComponents/VmlParser.jsx';

const ZoneName = styled.div`
  display: flex;
  justify-content: center;
  font-size: 20px;
  font-weight: bold;
`;

const ZoneMap = styled.div`
  display: flex;
  white-space: pre;
  font-family: 'Lucida Console', Monaco, monospace;
  font-size: 12px;
  font-weight: bold;
  justify-content: center;
`;

const RightPane = ({ zoneMap, zoneName }) => {
  return (
    <>
      <ZoneName>{zoneName}</ZoneName>
      <br />
      <br />
      <ZoneMap>
        <VmlParser vmlString={zoneMap} />
      </ZoneMap>
    </>
  );
};

const mapStateToProps = ({ zoneMap }) => {
  let map = zoneMap.split('\n');
  return {
    zoneName: map ? map[0] : '',
    zoneMap: map ? map.slice(2).join('\n') : ''
  };
};

export default connect(mapStateToProps)(RightPane);
