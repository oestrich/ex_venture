import {
  UPDATE_ROOM_INFO,
  UPDATE_ZONE_MAP,
  UPDATE_CHARACTER_INFO,
  UPDATE_CHARACTER_VITALS,
  UPDATE_CHARACTER_SKILLS,
  UPDATE_EVENT_STREAM
} from '../actions/actions.js';

const initialState = {
  roomInfo: '',
  zoneMap: '',
  characterInfo: '',
  characterVitals: '',
  characterSkills: '',
  eventStream: []
};

export default function(state = initialState, action) {
  switch (action.type) {
    case UPDATE_ROOM_INFO: {
    }
    case UPDATE_ZONE_MAP: {
    }
    case UPDATE_CHARACTER_INFO: {
    }
    case UPDATE_CHARACTER_VITALS: {
    }
    case UPDATE_CHARACTER_SKILLS: {
    }
    case UPDATE_EVENT_STREAM: {
      return { ...state, eventStream: [...state.eventStream, action.payload] };
    }
    default: {
      return state;
    }
  }
}
