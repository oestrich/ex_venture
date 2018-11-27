import {
  UPDATE_ROOM_INFO,
  UPDATE_ZONE_MAP,
  UPDATE_CHARACTER_INFO,
  UPDATE_CHARACTER_VITALS,
  UPDATE_CHARACTER_SKILLS,
  UPDATE_CHARACTER_PROMPT,
  UPDATE_EVENT_STREAM
} from '../actions/actions.js';

const initialState = {
  roomInfo: '',
  zoneMap: '',
  characterInfo: '',
  characterVitals: '',
  characterSkills: new Array(13).fill('').map((item, idx) => {
    return { key: `placeholder-${idx}` };
  }),
  characterPrompt: {
    hp: { current: 0, max: 0 },
    sp: { current: 0, max: 0 },
    ep: { current: 0, max: 0 },
    xp: 0
  },
  eventStream: []
};

export default function(state = initialState, action) {
  switch (action.type) {
    case UPDATE_ROOM_INFO: {
      return { ...state, roomInfo: action.payload };
    }
    case UPDATE_ZONE_MAP: {
      return { ...state, zoneMap: action.payload };
    }
    case UPDATE_CHARACTER_INFO: {
      return { ...state, characterInfo: action.payload };
    }
    case UPDATE_CHARACTER_VITALS: {
      return { ...state, characterVitals: action.payload };
    }
    case UPDATE_CHARACTER_SKILLS: {
      // add placeholder keys for empty action buttons
      console.log('ACTION.PAYLOAD', action.payload);
      const skills = action.payload.map((item, idx) => {
        if (!item.key) {
          return { key: `placeholder-${idx}` };
        } else {
          return item;
        }
      });
      return { ...state, characterSkills: skills };
    }
    case UPDATE_CHARACTER_PROMPT: {
      return { ...state, characterPrompt: action.payload };
    }
    case UPDATE_EVENT_STREAM: {
      return { ...state, eventStream: [...state.eventStream, action.payload] };
    }
    default: {
      return state;
    }
  }
}
