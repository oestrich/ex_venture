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
  awareness,
  agility
}) => {
  return (
    <>
      <CharacterName>{name ? `${name}  -  ${level}` : null}</CharacterName>
      <br />
      <br />
      <CharacterInfo>
        {name
          ? `You are a 33 year old ${charClass} hailing from Elwynn Forest`
          : null}
      </CharacterInfo>
      <br />
      <table>
        <tr>
          <td>STR:</td>
          <td>{strength}</td>
          <td>VIT:</td>
          <td>{vitality}</td>
          <td>AGI:</td>
          <td>{agility}</td>
        </tr>
        <tr>
          <td>WIL:</td>
          <td>{willpower}</td>
          <td>INT:</td>
          <td>{intelligence}</td>
          <td>AWA:</td>
          <td>{awareness}</td>
        </tr>
      </table>
      <br />
    </>
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
    awareness: v.awareness,
    agility: v.agility
  };
};

export default connect(mapStateToProps)(LeftPane);
