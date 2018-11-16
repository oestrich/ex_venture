import React, { Component } from 'react';
import styled, { css } from 'styled-components';

const RightPane = ({ className }) => {
  return <div className={className}>LeftPane</div>;
};

export default styled(RightPane)`
  flex: 1;
`;
