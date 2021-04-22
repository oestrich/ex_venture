import PropTypes from "prop-types";
import React, { useCallback, useState } from "react";
import { connect } from "react-redux";
import { RadioGroup } from "@headlessui/react";

import { Creators } from "../redux";

const classNames = (...classes) => {
  return classes.filter(Boolean).join(" ");
};

const CharacterSelect = ({ characters, selectedCharacter, setSelectedCharacter }) => {
  return (
    <RadioGroup value={selectedCharacter} onChange={setSelectedCharacter}>
      <RadioGroup.Label className="sr-only">Characters</RadioGroup.Label>
      <div className="relative bg-white rounded-md -space-y-px">
        {characters.map((character, characterIndex) => (
          <RadioGroup.Option
            key={character.name}
            value={character.token}
            className={({ checked }) => {
              return classNames(
                characterIndex === 0 ? "rounded-tl-md rounded-tr-md" : "",
                characterIndex === characters.length - 1 ? "rounded-bl-md rounded-br-md" : "",
                checked ? "bg-indigo-50 border-indigo-200 z-10" : "border-gray-200",
                "relative border p-4 flex flex-col cursor-pointer md:pl-4 md:pr-6 md:grid md:grid-cols-3 focus:outline-none",
              );
            }}
          >
            {({ active, checked }) => (
              <>
                <div className="flex items-center text-sm">
                  <span
                    className={classNames(
                      checked ? "bg-indigo-600 border-transparent" : "bg-white border-gray-300",
                      active ? "ring-2 ring-offset-2 ring-indigo-500" : "",
                      "h-4 w-4 rounded-full border flex items-center justify-center",
                    )}
                    aria-hidden="true"
                  >
                    <span className="rounded-full bg-white w-1.5 h-1.5" />
                  </span>
                  <RadioGroup.Label as="span" className="ml-3 font-medium text-gray-900">
                    {character.name}
                  </RadioGroup.Label>
                </div>
              </>
            )}
          </RadioGroup.Option>
        ))}
      </div>
    </RadioGroup>
  );
};

CharacterSelect.propTypes = {
  characters: PropTypes.object,
  selectedCharacter: PropTypes.string,
  setSelectedCharacter: PropTypes.func,
};

const CharacterSelectPage = ({ characters, submitCharacter }) => {
  let [selectedCharacter, setSelectedCharacter] = useState();

  const pickCharacter = useCallback(() => {
    submitCharacter(selectedCharacter);
  }, [submitCharacter, selectedCharacter]);

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
            <CharacterSelect
              characters={characters}
              selectedCharacter={selectedCharacter}
              setSelectedCharacter={setSelectedCharacter}
            />
          </div>

          <input
            type="button"
            value="Play &raquo;"
            className="btn btn-primary w-full cursor-pointer"
            onClick={pickCharacter}
          />
        </div>
      </div>
    </div>
  );
};

CharacterSelectPage.propTypes = {
  characters: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  submitCharacter: PropTypes.func.isRequired,
};

export default connect(null, {
  submitCharacter: Creators.selectCharacter,
})(CharacterSelectPage);
