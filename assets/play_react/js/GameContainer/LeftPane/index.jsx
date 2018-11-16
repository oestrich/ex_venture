import React, { Component } from 'react';
import styled, { css } from 'styled-components';

const LeftPane = ({ className }) => {
  return <div className={className}>LeftPane</div>;
};

export default styled(LeftPane)`
  flex: 1;
`;
