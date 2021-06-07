import PropTypes from "prop-types";
import React from "react";

import { Creators } from "../kalevala";

import Icon from "./Icon";

const verbIcons = {
  drop: () => <Icon icon="card-discard.svg" />,
  grab: () => <Icon icon="card-play.svg" />,
};

verbIcons.drop.displayName = "Drop";
verbIcons.grab.displayName = "Grab";

export const Verb = ({ verb, dispatch }) => {
  const onClick = () => {
    dispatch(
      Creators.socketSendEvent({
        topic: "system/send",
        data: {
          text: verb.send,
        },
      }),
    );
  };

  const verbIcon = verbIcons[verb.icon];

  return (
    <span className="inline-block border-b border-teal-600 cursor-pointer p-2 flex hover:bg-teal-600" onClick={onClick}>
      {verbIcon && verbIcon()} {verb.text}
    </span>
  );
};

Verb.propTypes = {
  dispatch: PropTypes.func.isRequired,
  verb: PropTypes.shape({
    icon: PropTypes.string,
    send: PropTypes.string.isRequired,
    text: PropTypes.string.isRequired,
  }),
};

export const ContextMenu = ({ verbs, dispatch }) => {
  return (
    <>
      {verbs.map((verb) => {
        return <Verb key={verb.send} verb={verb} dispatch={dispatch} />;
      })}
    </>
  );
};

ContextMenu.propTypes = {
  dispatch: PropTypes.func.isRequired,
  verbs: PropTypes.arrayOf(
    PropTypes.shape({
      send: PropTypes.string.isRequired,
    }),
  ),
};
