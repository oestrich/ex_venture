import { createReducer } from "../kalevala";

import { Types } from "./actions";

const INITIAL_STATE = {
  messages: [],
};

const channelBroadcast = (state, action) => {
  const { channelName, character, id, text } = action.data;

  const message = {
    channelName,
    character: {
      id: character.id,
      name: character.name,
    },
    id,
    text,
  };

  return { ...state, messages: [...state.messages, message] };
};

const HANDLERS = {
  [Types.CHANNEL_BROADCAST]: channelBroadcast,
};

export const channelReducer = createReducer(INITIAL_STATE, HANDLERS);
