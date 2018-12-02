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
  width: ${props => props.width};
  height: 5px;
  opacity: 0.5;
  box-shadow: 0 0 0 0;
  position: relative;
  left: -6px;
  top: -6px;
`;

const StatusBar = ({
  currentHp,
  currentSp,
  currentEp,
  maxHp,
  maxSp,
  maxEp,
  hpWidth,
  spWidth,
  epWidth
}) => {
  return (
    <FlexColumn>
      <BarContainer>
        <Bar color={theme.statusBar.hp} width={hpWidth}>
          {currentHp}/{maxHp}
        </Bar>
      </BarContainer>
      <BarContainer>
        <Bar color={theme.statusBar.sp} width={spWidth}>
          {currentSp}/{maxSp}
        </Bar>
      </BarContainer>
      <BarContainer>
        <Bar color={theme.statusBar.ep} width={epWidth}>
          {currentEp}/{maxEp}
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

const mapStateToProps = ({ characterVitals: cv }) => {
  return {
    currentHp: cv.health_points,
    currentSp: cv.skill_points,
    currentEp: cv.endurance_points,
    maxHp: cv.max_health_points,
    maxSp: cv.max_skill_points,
    maxEp: cv.max_endurance_points,
    hpWidth: (cv.health_points / cv.max_health_points) * 100 + '%',
    spWidth: (cv.skill_points / cv.max_skill_points) * 100 + '%',
    epWidth: (cv.endurance_points / cv.endurance_points) * 100 + '%'
  };
};

export default connect(mapStateToProps)(StatusBar);
