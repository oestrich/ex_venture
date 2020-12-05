import { promptReducer } from "./promptReducer";
import { Creators } from "./actions";

describe("prompt reducer", () => {
  test("resets the prompt state on clear", () => {
    let state = { index: 1, currentText: "Hello", displayText: "Hello" };

    state = promptReducer(state, Creators.promptClear());

    expect(state).toEqual({ index: -1, currentText: "", displayText: "" });
  });

  test("sets the current text", () => {
    let state = { index: 1, currentText: "Hello", displayText: "Hello" };

    state = promptReducer(state, Creators.promptSetCurrentText("hi"));

    expect(state).toEqual({ index: -1, currentText: "hi", displayText: "hi" });
  });

  test("adds current text to the history", () => {
    let state = { history: [], displayText: "hi" };

    state = promptReducer(state, Creators.promptHistoryAdd());

    expect(state).toMatchObject({ history: ["hi"] });
  });

  test("limits to 10 elements in history", () => {
    let state = { history: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], displayText: "hi" };

    state = promptReducer(state, Creators.promptHistoryAdd());

    expect(state).toMatchObject({ history: ["hi", "1", "2", "3", "4", "5", "6", "7", "8", "9"] });
  });

  test("skips adding to history if the same command", () => {
    let state = { history: ["hi"], displayText: "hi" };

    state = promptReducer(state, Creators.promptHistoryAdd());

    expect(state).toMatchObject({ history: ["hi"] });
  });

  test("scroll backwards in history", () => {
    let state = { history: ["hi"], index: -1, displayText: "" };

    state = promptReducer(state, Creators.promptHistoryScrollBackward());

    expect(state).toMatchObject({ displayText: "hi" });
  });

  test("scroll backwards, end of history", () => {
    let state = { history: ["hi"], index: 1, displayText: "" };

    state = promptReducer(state, Creators.promptHistoryScrollBackward());

    expect(state).toEqual(state);
  });

  test("scroll forward in history", () => {
    let state = { history: ["hi"], index: 1, displayText: "" };

    state = promptReducer(state, Creators.promptHistoryScrollForward());

    expect(state).toMatchObject({ displayText: "hi" });
  });

  test("scroll forward in history, at the current text", () => {
    let state = { history: ["hi"], index: 0, currentText: "hi", displayText: "" };

    state = promptReducer(state, Creators.promptHistoryScrollForward());

    expect(state).toMatchObject({ index: 0, displayText: "hi" });
  });
});
