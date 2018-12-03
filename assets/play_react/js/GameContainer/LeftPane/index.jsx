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

const LeftPane = ({
  className,
  name,
  level,
  charClass,
  willpower,
  vitality,
  strength,
  intelligence,
  endurance,
  awareness
}) => {
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
      <br />
    </div>
  );
};

const mapStateToProps = ({ characterInfo: i, characterVitals: v }) => {
  return {
    name: capitalize(i.name),
    level: i.level,
    charClass: i.class.name,
    willpower: v.willpower,
    vitality: v.vitality,
    strength: v.strength,
    intelligence: v.intelligence,
    endurance: v.endurance,
    awareness: v.awareness
  };
};

export default connect(mapStateToProps)(styled(LeftPane)`
  padding: 2em 2em 2em 2em;
  flex: 1;
  background-color: ${theme.bgSecondary};
`);
