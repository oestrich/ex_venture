import React from 'react';
import { connect } from 'react-redux';

const ActionBar = ({ characterSkills }) => (
  <div> ActionBar {characterSkills}</div>
);

const mapStateToProps = state => {
  return {
    characterSkills: state.characterSkills
  };
};

export default connect(mapStateToProps)(ActionBar);
