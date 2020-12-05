import { applyMiddleware, combineReducers } from "redux";
import thunk from "redux-thunk";

import { Types, Creators } from "./actions";
import { createReducer } from "./createReducer";
import { promptReducer } from "./promptReducer";
import { socketReducer } from "./socketReducer";

export const getPromptState = (state) => {
  return state.prompt;
};

export const getPromptDisplayText = (state) => {
  return getPromptState(state).displayText;
};

export const getSocketState = (state) => {
  return state.socket;
};

export const getSocketConnectionState = (state) => {
  return getSocketState(state).connected;
};

export const getSocketLines = (state) => {
  let socketState = getSocketState(state);

  return socketState.lines;
};

export const kalevalaMiddleware = (eventHandlers) => {
  return applyMiddleware(thunk.withExtraArgument({ eventHandlers }));
};

export const kalevalaReducers = combineReducers({
  prompt: promptReducer,
  socket: socketReducer,
});

export { createReducer, Creators, promptReducer, socketReducer, Types };
