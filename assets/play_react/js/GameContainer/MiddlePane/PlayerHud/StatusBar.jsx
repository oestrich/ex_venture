import React from 'react';
import styled from 'styled-components';
import { connect } from 'react-redux';
import { theme } from '../../../theme.js';

const FlexColumn = styled.div`
  display: flex;
  justify-content: space-between;
  padding-top: 5px;
`;

const BarContainer = styled.div`
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
  line-height: 5px;
`;

const Bar = styled(BarContainer)`
  color: ${theme.text}
  background: ${props => props.color};
  width: 100%;
  height: 5px;
  opacity: 0.5;
  box-shadow: 0 0 0 0;
  position: relative;
  left: -6px;
  top: -6px;
`;

const StatusBar = props => {
  return (
    <FlexColumn>
      <BarContainer>
        <Bar color={theme.statusBar.hp}>
          {props.prompt.hp.current}/{props.prompt.hp.max}
        </Bar>
      </BarContainer>
      <BarContainer>
        <Bar color={theme.statusBar.sp}>
          {props.prompt.sp.current}/{props.prompt.sp.max}
        </Bar>
      </BarContainer>
      <BarContainer>
        <Bar color={theme.statusBar.ep}>
          {props.prompt.ep.current}/{props.prompt.ep.max}
        </Bar>
      </BarContainer>
    </FlexColumn>
  );
};

StatusBar.defaultProps = {
  prompt: {
    hp: { current: 0, max: 0 },
    sp: { current: 0, max: 0 },
    ep: { current: 0, max: 0 },
    xp: 0
  }
};

const mapStateToProps = state => {
  console.log('state', state);
  return {
    prompt: state.characterPrompt
  };
};

export default connect(mapStateToProps)(StatusBar);
