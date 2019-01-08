import { channel } from '../../channel.js';

export const UPDATE_ROOM_INFO = 'UPDATE_ROOM_INFO';
export const UPDATE_ZONE_MAP = 'UPDATE_ZONE_MAP';
export const UPDATE_CHARACTER_INFO = 'UPDATE_CHARACTER_INFO';
export const UPDATE_CHARACTER_VITALS = 'UPDATE_CHARACTER_VITALS';
export const UPDATE_CHARACTER_SKILLS = 'UPDATE_CHARACTER_SKILLS';
export const UPDATE_CHARACTER_PROMPT = 'UPDATE_CHARACTER_PROMPT';
export const UPDATE_EVENT_STREAM = 'UPDATE_EVENT_STREAM';
export const ARCHIVE_AND_CLEAR_EVENT_STREAM = 'ARCHIVE_AND_CLEAR_EVENT_STREAM';
export const ADD_TO_COMMAND_HISTORY = 'SEND_MSG_TO_SERVER";';

const GMCP_ROOM_INFO = 'Room.Info';
const GMCP_ZONE_MAP = 'Zone.Map';
const GMCP_CHARACTER_INFO = 'Character.Info';
const GMCP_CHARACTER_VITALS = 'Character.Vitals';
const GMCP_CHARACTER_SKILLS = 'Character.Skills';

const ACTIONBAR_LENGTH = 13;

export const send = message => {
  channel.push('recv', { message });
  return { type: ADD_TO_COMMAND_HISTORY, payload: message };
};

export const initPhxChannelSubscriptions = () => {
  return (dispatch, getState) => {
    channel.on('gmcp', response => {
      switch (response.module) {
        case GMCP_ROOM_INFO: {
          const roomInfo = JSON.parse(response.data);

          // Preserve order of exits across all rooms
          const exitsOrderMap = {
            north: 1,
            south: 2,
            west: 3,
            east: 4,
            up: 5,
            down: 6
          };
          roomInfo.exits.sort((a, b) => {
            return exitsOrderMap[a.direction] - exitsOrderMap[b.direction];
          });

          // upon new room, archive current event stream and clear ui
          if (getState().roomInfo.id !== roomInfo.id) {
            dispatch({
              type: ARCHIVE_AND_CLEAR_EVENT_STREAM
            });
          }
          return dispatch({
            type: UPDATE_ROOM_INFO,
            payload: roomInfo
          });
        }
        case GMCP_ZONE_MAP: {
          return dispatch({
            type: UPDATE_ZONE_MAP,
            payload: JSON.parse(response.data).map
          });
        }
        case GMCP_CHARACTER_INFO: {
          return dispatch({
            type: UPDATE_CHARACTER_INFO,
            payload: JSON.parse(response.data)
          });
        }
        case GMCP_CHARACTER_VITALS: {
          const vitals = JSON.parse(response.data);
          return dispatch({
            type: UPDATE_CHARACTER_VITALS,
            payload: vitals
          });
        }
        case GMCP_CHARACTER_SKILLS: {
          let skills = JSON.parse(response.data).skills;
          const emptySkills = new Array(ACTIONBAR_LENGTH - skills.length).fill(
            {}
          );
          skills = skills.concat(emptySkills);
          return dispatch({
            type: UPDATE_CHARACTER_SKILLS,
            payload: skills
          });
        }
      }
    });
    channel.on('option', response => {});

    channel.on('prompt', response => {
      // TODO: Future deprecation: Status prompt updates will come from Character.Vitals GMCP module
      // However there may be other non character vitals prompt updates that are sent over
      // the prompt channel
      // if (prompt) {
      //   dispatch({ type: UPDATE_CHARACTER_PROMPT, payload: prompt });
      // }
    });
    channel.on('echo', response => {
      // squelch room updates in main event log since using GMCP:Room.Info for room data
      if (response.message.match(/{room}/g)) {
        return;
      }
      dispatch({ type: UPDATE_EVENT_STREAM, payload: response });
    });
    channel.on('disconnect', response => {
      console.log('[Channel: DISCONNECT]', response);
    });
    channel.on('phx_close', response => {
      console.log('[Channel: PHX_CLOSE]', response);
    });
    channel.on('phx_error', response => {
      console.log('[Channel: PHX_ERROR]', response);
    });
    channel.on('phx_reply', response => {
      console.log('[Channel: PHX_REPLY]', response);
    });
  };
};
