import { createReducer, Types as KalevalaTypes } from "../kalevala";

import { Types } from "./actions";

const INITIAL_STATE = {
  character: null,
  contexts: {},
  inventory: [],
  miniMap: [],
  room: null,
  vitals: null,
};

const characterEntered = (state, action) => {
  const { character } = action.data;

  const characters = [...state.room.characters, character];

  return { ...state, room: { ...state.room, characters } };
};

const characterLeft = (state, action) => {
  const { character } = action.data;

  const characters = state.room.characters.filter((existingCharacter) => {
    return existingCharacter.id != character.id;
  });

  return { ...state, room: { ...state.room, characters } };
};

const characterLoggedIn = (state, action) => {
  const { character } = action.data;
  return { ...state, character: character };
};

const eventReceived = (state, action) => {
  const { event } = action.data;

  switch (event.topic) {
    case "Character.Vitals": {
      return { ...state, vitals: event.data };
    }

    case "Context.Verbs": {
      const { contexts } = state;
      const { verbs, context, type, id } = event.data;

      contexts[`${context}:${type}:${id}`] = verbs;

      return { ...state, contexts: contexts };
    }

    case "Inventory.All": {
      const { item_instances } = event.data;
      return { ...state, inventory: item_instances };
    }

    case "Inventory.DropItem": {
      return dropItem(state, event);
    }

    case "Inventory.PickupItem": {
      return pickupItem(state, event);
    }

    case "Room.Info": {
      return { ...state, room: event.data };
    }

    case "Zone.MiniMap": {
      return { ...state, miniMap: event.data.mini_map };
    }

    default: {
      return state;
    }
  }
};

const dropItem = (state, event) => {
  const { item_instance } = event.data;
  let { inventory } = state;
  inventory = inventory.filter((instance) => instance.id != item_instance.id);
  return { ...state, inventory: inventory };
};

const pickupItem = (state, event) => {
  const { item_instance } = event.data;
  return { ...state, inventory: [item_instance, ...state.inventory] };
};

const eventClearVerbs = (state, event) => {
  const { contexts } = state;
  const { context, type, id } = event.data;

  delete contexts[`${context}:${type}:${id}`];

  return { ...state, contexts: contexts };
};

const HANDLERS = {
  [KalevalaTypes.SOCKET_RECEIVED_EVENT]: eventReceived,
  [KalevalaTypes.SOCKET_CLEAR_VERBS]: eventClearVerbs,
  [Types.LOGGED_IN]: characterLoggedIn,
  [Types.ROOM_CHARACTER_ENTERED]: characterEntered,
  [Types.ROOM_CHARACTER_LEFT]: characterLeft,
};

export const eventsReducer = createReducer(INITIAL_STATE, HANDLERS);
