import { socketReducer } from "./socketReducer";
import { Creators } from "./actions";

describe("socket reducer", () => {
  test("socket connected", () => {
    let state = { lines: [], connected: false };

    state = socketReducer(state, Creators.socketConnected());

    expect(state.connected).toEqual(true);
  });

  test("socket disconnected", () => {
    let state = { lines: [], connected: true };

    state = socketReducer(state, Creators.socketDisconnected());

    expect(state.connected).toEqual(false);
  });
});
