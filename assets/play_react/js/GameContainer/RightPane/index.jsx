import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled from 'styled-components';
import { theme } from '../../theme.js';

const ZoneName = styled.div`
  display: flex;
  justify-content: center;
  font-size: 20px;
  font-weight: bold;
`;

const ZoneMap = styled.div`
  white-space: pre;
  font-family: 'Lucida Console', Monaco, monospace;
  font-size: 12px;
  font-weight: bold;
`;

const RightPane = ({ zoneMap, zoneName }) => {
  return (
    <>
      <ZoneName>{zoneName}</ZoneName>
      <br />
      <br />
      <ZoneMap>
        {zoneMap.map(row => (
          <div>{row}</div>
        ))}
      </ZoneMap>
    </>
  );
};

const mapStateToProps = ({ zoneMap }) => {
  let map = zoneMap;

  map = map.replace(/\\]/g, ']');
  map = map.replace(/\\\[/g, '[');
  map = map.replace(/{map:default}/g, '');
  map = map.replace(/{map:blue}/g, '');
  map = map.replace(/{map:brown}/g, '');
  map = map.replace(/{map:dark-green}/g, '');
  map = map.replace(/{map:green}/g, '');
  map = map.replace(/{map:grey}/g, '');
  map = map.replace(/{map:light-grey}/g, '');
  map = map.replace(/{\/[\w:-]+}/g, '');
  map = map.split('\n');

  return {
    zoneName: map ? map[0] : '',
    zoneMap: map ? map.slice(2) : []
  };
};

export default connect(mapStateToProps)(RightPane);
