import React, { Component } from 'react';
import { connect } from 'react-redux';
import styled, { css } from 'styled-components';
import { theme } from '../../theme.js';
import { capitalize } from '../../utils/utils.js';

const CharacterName = styled.div`
  display: flex;
  justify-content: center;
  font-size: 20px;
  font-weight: bold;
`;

const CharacterInfo = styled.div`
  display: flex;
  justify-content: center;
`;

// TODO: Long string will not create newlines, it will increase container size
const LeftPane = ({ className, name, level, charClass }) => {
  // const vitals = characterVitals ? JSON.parse(characterVitals) : {};
  // const charInfo = characterInfo ? JSON.parse(characterInfo) : {};
  return (
    <div className={className}>
      <CharacterName>{name ? `${name}  -  ${level}` : null}</CharacterName>
      <br />
      <br />
      <CharacterInfo>
        {name
          ? `You are a 33 year old ${charClass} hailing from Elwynn Forest`
          : null}
      </CharacterInfo>
    </div>
  );
};

const mapStateToProps = ({ characterInfo: info, characterVitals: vitals }) => {
  console.log('characterInfo', info);
  return {
    name: capitalize(info.name),
    level: info.level,
    charClass: info.class.name,
    willpower: vitals.willpower,
    vitality: vitals.vitality,
    strength: vitals.strength,
    intelligence: vitals.intelligence,
    endurance: vitals.endurance,
    awareness: vitals.awareness
  };
};

LeftPane.defaultProps = { characterVitals: '{}', characterInfo: '{}' };

export default connect(mapStateToProps)(styled(LeftPane)`
  padding: 2em 2em 2em 2em;
  flex: 1;
  background-color: ${theme.bgSecondary};
`);
