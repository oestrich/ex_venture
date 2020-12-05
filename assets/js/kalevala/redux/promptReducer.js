import { Types } from "./actions";
import { createReducer } from "./createReducer";

const INITIAL_STATE = {
  index: -1,
  history: [],
  currentText: "",
  displayText: "",
};

export const promptClear = (state) => {
  return { ...state, index: -1, currentText: "", displayText: "" };
};

export const promptSetCurrentText = (state, action) => {
  const { text } = action.data;
  return { ...state, index: -1, currentText: text, displayText: text };
};

export const promptHistoryAdd = (state) => {
  if (state.history[0] == state.displayText) {
    return { ...state, index: -1 };
  } else {
    let history = [state.displayText, ...state.history];
    history = history.slice(0, 10);
    return { ...state, history: history };
  }
};

export const promptHistoryScrollBackward = (state) => {
  let index = state.index + 1;

  if (state.history[index] != undefined) {
    return { ...state, index: index, displayText: state.history[index] };
  }

  return state;
};

export const promptHistoryScrollForward = (state) => {
  let index = state.index - 1;

  if (index == -1) {
    return { ...state, index: 0, displayText: state.currentText };
  } else if (state.history[index] != undefined) {
    return { ...state, index: index, displayText: state.history[index] };
  }

  return state;
};

export const HANDLERS = {
  [Types.PROMPT_CLEAR]: promptClear,
  [Types.PROMPT_HISTORY_ADD]: promptHistoryAdd,
  [Types.PROMPT_HISTORY_SCROLL_BACKWARD]: promptHistoryScrollBackward,
  [Types.PROMPT_HISTORY_SCROLL_FORWARD]: promptHistoryScrollForward,
  [Types.PROMPT_SET_CURRENT_TEXT]: promptSetCurrentText,
};

export const promptReducer = createReducer(INITIAL_STATE, HANDLERS);
