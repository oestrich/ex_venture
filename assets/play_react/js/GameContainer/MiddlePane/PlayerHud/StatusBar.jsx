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

// StatusBar.defaultProps = {
//   prompt: {
//     hp: { current: 0, max: 0 },
//     sp: { current: 0, max: 0 },
//     ep: { current: 0, max: 0 },
//     xp: 0
//   }
// };

const mapStateToProps = ({ characterVitals: vitals }) => {
  return {
    currentHp: vitals.health_points,
    currentSp: vitals.skill_points,
    currentEp: vitals.endurance_points,
    maxHp: vitals.max_health_points,
    maxSp: vitals.max_skill_points,
    maxEp: vitals.max_endurance_points,
    hpWidth: (vitals.health_points / vitals.max_health_points) * 100 + '%',
    spWidth: (vitals.skill_points / vitals.max_skill_points) * 100 + '%',
    epWidth: (vitals.endurance_points / vitals.endurance_points) * 100 + '%'
  };
};

export default connect(mapStateToProps)(StatusBar);
