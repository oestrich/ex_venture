import { Creators as KalevalaCreators } from "../kalevala";

export const Types = {
  CHANNEL_BROADCAST: "CHANNEL_BROADCAST",
  LOGIN_ACTIVE: "LOGIN_ACTIVE",
  LOGGED_IN: "LOGGED_IN",
  ROOM_CHARACTER_ENTERED: "ROOM_CHARACTER_ENTERED",
  ROOM_CHARACTER_LEFT: "ROOM_CHARACTER_LEFT",
};

export const Creators = {
  channelBroadcast: (channelName, character, id, text) => {
    return { type: Types.CHANNEL_BROADCAST, data: { channelName, character, id, text } };
  },
  login: (username, password) => {
    return (dispatch) => {
      const event = {
        topic: "Login",
        data: { username, password },
      };

      dispatch(KalevalaCreators.socketSendEvent(event));
    };
  },
  loginActive: () => {
    return { type: Types.LOGIN_ACTIVE };
  },
  loggedIn: (character) => {
    return { type: Types.LOGGED_IN, data: { character } };
  },
  moveNorth: () => {
    return (dispatch) => {
      const event = {
        topic: "system/send",
        data: { text: "north" },
      };

      dispatch(KalevalaCreators.socketSendEvent(event));
    };
  },
  moveSouth: () => {
    return (dispatch) => {
      const event = {
        topic: "system/send",
        data: { text: "south" },
      };

      dispatch(KalevalaCreators.socketSendEvent(event));
    };
  },
  moveWest: () => {
    return (dispatch) => {
      const event = {
        topic: "system/send",
        data: { text: "west" },
      };

      dispatch(KalevalaCreators.socketSendEvent(event));
    };
  },
  moveEast: () => {
    return (dispatch) => {
      const event = {
        topic: "system/send",
        data: { text: "east" },
      };

      dispatch(KalevalaCreators.socketSendEvent(event));
    };
  },
  moveUp: () => {
    return (dispatch) => {
      const event = {
        topic: "system/send",
        data: { text: "up" },
      };

      dispatch(KalevalaCreators.socketSendEvent(event));
    };
  },
  moveDown: () => {
    return (dispatch) => {
      const event = {
        topic: "system/send",
        data: { text: "down" },
      };

      dispatch(KalevalaCreators.socketSendEvent(event));
    };
  },
  roomCharacterEntered: (character) => {
    return { type: Types.ROOM_CHARACTER_ENTERED, data: { character: character } };
  },
  roomCharacterLeft: (character) => {
    return { type: Types.ROOM_CHARACTER_LEFT, data: { character: character } };
  },
  selectCharacter: (character) => {
    return (dispatch) => {
      const event = {
        topic: "Login.Character",
        data: { character },
      };

      dispatch(KalevalaCreators.socketSendEvent(event));
    };
  },
};
