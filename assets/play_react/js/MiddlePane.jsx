import React, { Component } from 'react';
import styled, { css } from 'styled-components';

const MiddlePane = ({ className }) => {
  return <div className={className}>MiddlePane</div>;
};

export default styled(MiddlePane)`
  flex: 0 0 768px;
`;
