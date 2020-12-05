import PropTypes from "prop-types";
import React from "react";
import { connect } from "react-redux";

import { Creators } from "../redux";

class CharacterSelect extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      character: "",
    };
  }

  render() {
    const submitCharacter = () => {
      this.props.selectCharacter(this.state.character);
    };

    const selectClick = (e) => {
      e.preventDefault();
      submitCharacter();
    };

    const onKeyDown = (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        submitCharacter();
      }
    };

    return (
      <div className="h-full bg-white p-4 px-3 py-10 bg-gray-200 flex justify-center">
        <div className="w-full max-w-sm">
          <h1 className="text-6xl text-center">Kantele</h1>

          <div className="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
            <p className="text-center mb-4">
              Enter in a character name to play as. This is how characters will refer to you.
            </p>

            <p className="mb-4 text-sm text-center italic">Note: At the moment any character name will work.</p>

            <div className="mb-4">
              <input
                autoFocus={true}
                className="input"
                id="character"
                type="text"
                placeholder="Character Name"
                value={this.state.character}
                onKeyDown={onKeyDown}
                onChange={(e) => {
                  this.setState({ character: e.target.value });
                }}
              />
            </div>

            <button className="btn-primary w-full" onClick={selectClick}>
              Select
            </button>
          </div>
        </div>
      </div>
    );
  }
}

CharacterSelect.propTypes = {
  selectCharacter: PropTypes.func.isRequired,
};

export default connect(null, {
  selectCharacter: Creators.selectCharacter,
})(CharacterSelect);
