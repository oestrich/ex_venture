import React, { Component } from 'react';
import styled, { css } from 'styled-components';

const RightPane = ({ className }) => {
  return <div className={className}>RightPane</div>;
};

export default styled(RightPane)`
  flex: 1;
`;
