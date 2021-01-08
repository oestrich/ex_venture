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
    const { characters } = this.props;

    const submitCharacter = () => {
      if (this.state.character != "") {
        this.props.selectCharacter(this.state.character);
      }
    };

    const selectCharacter = (e) => {
      this.setState({ character: e.target.value });
    };

    const selectClick = (e) => {
      e.preventDefault();
      submitCharacter();
    };

    return (
      <div className="h-full bg-white p-4 px-3 py-10 bg-gray-200 flex justify-center">
        <div className="w-full max-w-sm">
          <h1 className="text-6xl text-center">ExVenture</h1>

          <div className="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
            <p className="text-center mb-4">
              Pick which character to play as. Create another from your{" "}
              <a href="/profile" className="underline text-blue-500">
                profile
              </a>
              .
            </p>

            <div className="mb-4 flex flex-col">
              {characters.map((character) => {
                return (
                  <label key={character.name} className="text-xl">
                    <input
                      name="character"
                      value={character.token}
                      onChange={selectCharacter}
                      type="radio"
                      className="m-2"
                    />
                    {character.name}
                  </label>
                );
              })}
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
  characters: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  selectCharacter: PropTypes.func.isRequired,
};

export default connect(null, {
  selectCharacter: Creators.selectCharacter,
})(CharacterSelect);
