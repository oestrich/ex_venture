import { createReducer } from "../kalevala";

import { Types } from "./actions";

const INITIAL_STATE = {
  active: false,
  loggedIn: false,
};

const loginActive = (state) => {
  return { ...state, active: true };
};

const loggedIn = (state) => {
  return { ...state, loggedIn: true };
};

const HANDLERS = {
  [Types.LOGIN_ACTIVE]: loginActive,
  [Types.LOGGED_IN]: loggedIn,
};

export const loginReducer = createReducer(INITIAL_STATE, HANDLERS);
