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
      console.log(`[Channel: GMCP - ${response.module}]`, response);
      switch (response.module) {
        case GMCP_ROOM_INFO: {
          return dispatch({
            type: UPDATE_ROOM_INFO,
            payload: JSON.parse(response.data)
          });
        }
        case GMCP_ZONE_MAP: {
          return dispatch({
            type: UPDATE_ZONE_MAP,
            payload: response.data
          });
        }
        case GMCP_CHARACTER_INFO: {
          return dispatch({
            type: UPDATE_CHARACTER_INFO,
            payload: response.data
          });
        }
        case GMCP_CHARACTER_VITALS: {
          return dispatch({
            type: UPDATE_CHARACTER_VITALS,
            payload: response.data
          });
        }
        case GMCP_CHARACTER_SKILLS: {
          let skills = JSON.parse(response.data).skills;
          let emptySkills = new Array(13 - skills.length).fill({});
          skills = skills.concat(emptySkills);
          return dispatch({
            type: UPDATE_CHARACTER_SKILLS,
            payload: skills
          });
        }
      }
    });
    channel.on('option', response => {
      console.log('[Channel: OPTION]', response);
    });
    // channel.on('prompt', response => {
    //   console.log('[Channel: PROMPT]', response);
    //   dispatch({ type: UPDATE_EVENT_STREAM, payload: response });
    // });
    channel.on('echo', response => {
      // squelch room updates
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
