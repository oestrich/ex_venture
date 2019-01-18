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
  color: black;
  font-weight: bold;
  font-family: ${theme.font};
  flex: 1;
  display: inline-block;
  border: 0px;
  background: #1d4651;
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
  background: ${props => props.color};
  width: ${props => props.width};
  height: 5px;
  opacity: 0.5;
  box-shadow: 0 0 0 0;
  position: relative;
  float: left;
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
          <div>
            {currentHp}/{maxHp}
          </div>
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

const mapStateToProps = ({ characterVitals: v }) => {
  return {
    currentHp: v.health_points,
    currentSp: v.skill_points,
    currentEp: v.endurance_points,
    maxHp: v.max_health_points,
    maxSp: v.max_skill_points,
    maxEp: v.max_endurance_points,
    hpWidth: (v.health_points / v.max_health_points) * 100 + '%',
    spWidth: (v.skill_points / v.max_skill_points) * 100 + '%',
    epWidth: (v.endurance_points / v.endurance_points) * 100 + '%'
  };
};

export default connect(mapStateToProps)(StatusBar);
