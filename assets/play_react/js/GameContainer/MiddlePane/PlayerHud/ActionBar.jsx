import React from 'react';
import styled from 'styled-components';
import { connect } from 'react-redux';

const ActionButton = styled.div`
  display: inline;
`;

const ActionBar = ({ characterSkills }) => (
  <div>
    {' '}
    {characterSkills.map(skill => (
      <ActionButton>{skill.name}</ActionButton>
    ))}
  </div>
);

const mapStateToProps = state => {
  return {
    characterSkills: state.characterSkills
  };
};

export default connect(mapStateToProps)(ActionBar);
