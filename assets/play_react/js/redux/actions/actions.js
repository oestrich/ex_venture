import { channel } from '../../channel.js';

export const UPDATE_ROOM_INFO = 'UPDATE_ROOM_INFO';
export const UPDATE_ZONE_MAP = 'UPDATE_ZONE_MAP';
export const UPDATE_CHARACTER_INFO = 'UPDATE_CHARACTER_INFO';
export const UPDATE_CHARACTER_VITALS = 'UPDATE_CHARACTER_VITALS';
export const UPDATE_CHARACTER_SKILLS = 'UPDATE_CHARACTER_SKILLS';
export const UPDATE_CHARACTER_PROMPT = 'UPDATE_CHARACTER_PROMPT';
export const UPDATE_EVENT_STREAM = 'UPDATE_EVENT_STREAM';
export const ARCHIVE_AND_CLEAR_EVENT_STREAM = 'ARCHIVE_AND_CLEAR_EVENT_STREAM';

const GMCP_ROOM_INFO = 'Room.Info';
const GMCP_ZONE_MAP = 'Zone.Map';
const GMCP_CHARACTER_INFO = 'Character.Info';
const GMCP_CHARACTER_VITALS = 'Character.Vitals';
const GMCP_CHARACTER_SKILLS = 'Character.Skills';

const ACTIONBAR_LENGTH = 13;

export const initSubscriptions = () => {
  return (dispatch, getState) => {
    console.log('Initializing subscriptions...');
    channel.on('gmcp', response => {
      console.log(`[Channel: GMCP - ${response.module}]`, response);
      switch (response.module) {
        case GMCP_ROOM_INFO: {
          const roomInfo = JSON.parse(response.data);
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
          const vitals = JSON.parse(response.data);
          return dispatch({
            type: UPDATE_CHARACTER_VITALS,
            payload: vitals
          });
        }
        case GMCP_CHARACTER_SKILLS: {
          let skills = JSON.parse(response.data).skills;
          let emptySkills = new Array(ACTIONBAR_LENGTH - skills.length).fill(
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
    channel.on('option', response => {
      console.log('[Channel: OPTION]', response);
    });

    // Future deprecation: Status prompt updates will come from Character.Vitals GMCP module
    // However there may be other none character vitals prompt updates that are sent over
    // the prompt channel
    channel.on('prompt', response => {
      console.log('[Channel: PROMPT]', response);
      // const prompt = parsePrompt(response.message);
      // console.log('parsedPrompt', prompt);
      // if (prompt) {
      //   dispatch({ type: UPDATE_CHARACTER_PROMPT, payload: prompt });
      // }
    });
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

// const parsePrompt = msg => {
//   const re1 = '.*?'; // Non-greedy match on filler
//   const re2 = '(\\d+)'; // Integer Number 1
//   const re3 = '.*?'; // Non-greedy match on filler
//   const re4 = '(\\d+)'; // Integer Number 2
//   const re5 = '.*?'; // Non-greedy match on filler
//   const re6 = '(\\d+)'; // Integer Number 3
//   const re7 = '.*?'; // Non-greedy match on filler
//   const re8 = '(\\d+)'; // Integer Number 4
//   const re9 = '.*?'; // Non-greedy match on filler
//   const re10 = '(\\d+)'; // Integer Number 5
//   const re11 = '.*?'; // Non-greedy match on filler
//   const re12 = '(\\d+)'; // Integer Number 6
//   const re13 = '.*?'; // Non-greedy match on filler
//   const re14 = '(\\d+)'; // Integer Number 7

//   const regex =
//     '.*?\\d+.*?(\\d+).*?(\\d+).*?(\\d+).*?(\\d+).*?(\\d+).*?(\\d+).*?(\\d+)';
//   const p = new RegExp(
//     re1 +
//       re2 +
//       re3 +
//       re4 +
//       re5 +
//       re6 +
//       re7 +
//       re8 +
//       re9 +
//       re10 +
//       re11 +
//       re12 +
//       re13 +
//       re14,
//     ['i']
//   );
//   const m = p.exec(msg);
//   if (!m) {
//     return null;
//   }

//   return {
//     hp: { current: m[1], max: m[2] },
//     sp: { current: m[3], max: m[4] },
//     ep: { current: m[5], max: m[6] },
//     xp: m[7]
//   };
// };
