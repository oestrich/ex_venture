import React from 'react';
import styled from 'styled-components';

const FlexColumn = styled.div`
  display: flex;
  justify-content: space-between;
  padding-top: 5px;
`;

const Bar = styled.div`
  flex: 1;
  display: inline-block;
  color: #444;
  border: 1px solid #6177c8;
  background: #879ade;
  box-shadow: 0 2px 5px 0px #000000;
  border-radius: 5px;
  vertical-align: middle;
  max-height: 35px;
  height: 5px;
  padding: 5px;
  text-align: center;
`;

const StatusBar = props => {
  return (
    <FlexColumn>
      <Bar />
      <Bar />
      <Bar />
    </FlexColumn>
  );
};

export default StatusBar;
