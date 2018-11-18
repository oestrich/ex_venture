import { channel } from '../../channel.js';

export const UPDATE_ROOM_INFO = 'UPDATE_ROOM_INFO';
export const UPDATE_ZONE_MAP = 'UPDATE_ZONE_MAP';
export const UPDATE_CHARACTER_INFO = 'UPDATE_CHARACTER_INFO';
export const UPDATE_CHARACTER_VITALS = 'UPDATE_CHARACTER_VITALS';
export const UPDATE_CHARACTER_SKILLS = 'UPDATE_CHARACTER_SKILLS';
export const UPDATE_EVENT_STREAM = 'UPDATE_EVENT_STREAM';

const GMCP_ROOM_INFO = 'Room.Info';
const GMCP_ZONE_MAP = 'Zone.Map';
const GMCP_CHARACTER_INFO = 'Character.Info';
const GMCP_CHARACTER_VITALS = 'Character.Vitals';
const GMCP_CHARACTER_SKILLS = 'Character.Skills';

export const initSubscriptions = () => {
  return dispatch => {
    console.log('Initializing subscriptions...');
    channel.on('gmcp', response => {
      console.log('[Channel: GMCP]', response);
      switch (response.module) {
        case GMCP_ROOM_INFO: {
          dispatch({ type: UPDATE_ROOM_INFO, payload: response.data });
        }
        case GMCP_ZONE_MAP: {
          dispatch({ type: UPDATE_ZONE_MAP, payload: response.data });
        }
        case GMCP_CHARACTER_INFO: {
          dispatch({ type: UPDATE_CHARACTER_INFO, payload: response.data });
        }
        case GMCP_CHARACTER_VITALS: {
          dispatch({ type: UPDATE_CHARACTER_VITALS, payload: response.data });
        }
        case GMCP_CHARACTER_SKILLS: {
          dispatch({ type: UPDATE_CHARACTER_SKILLS, payload: response.data });
        }
      }
    });
    channel.on('option', response => {
      console.log('[Channel: OPTION]', response);
    });
    channel.on('prompt', response => {
      console.log('[Channel: PROMPT]', response);
      dispatch({ type: UPDATE_EVENT_STREAM, payload: response.message });
    });
    channel.on('echo', response => {
      console.log('[Channel: ECHO]', response);
      dispatch({ type: UPDATE_EVENT_STREAM, payload: response.message });
    });
    channel.on('disconnect', response => {
      console.log('[Channel: DISCONNECT]', response);
    });
  };
};
