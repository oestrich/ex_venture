import {
  UPDATE_ROOM_INFO,
  UPDATE_ZONE_MAP,
  UPDATE_CHARACTER_INFO,
  UPDATE_CHARACTER_VITALS,
  UPDATE_CHARACTER_SKILLS,
  UPDATE_CHARACTER_PROMPT,
  UPDATE_EVENT_STREAM,
  ARCHIVE_AND_CLEAR_EVENT_STREAM,
  ADD_TO_COMMAND_HISTORY
} from '../actions/actions.js';

const initialState = {
  roomInfo: {
    name: '',
    description: '',
    players: [],
    npcs: [],
    shops: [],
    items: [],
    exits: []
  },
  zoneMap: '',
  characterInfo: {
    name: null,
    class: { name: null },
    level: null
  },
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
  eventStream: [],
  eventStreamArchive: [],
  cmdHistory: []
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
      // append unique keys to empty skill slots
      // so react can stop barking about unique keys on lists
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
    case ARCHIVE_AND_CLEAR_EVENT_STREAM: {
      const oldEventStream = state.eventStream.slice();
      return { ...state, eventStreamArchive: oldEventStream, eventStream: [] };
    }
    case ADD_TO_COMMAND_HISTORY: {
      return { ...state, cmdHistory: [...state.cmdHistory, action.payload] };
    }
    default: {
      return state;
    }
  }
}
