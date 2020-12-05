// Inspired/copied from reduxsauce

const isNil = (object) => {
  return object === null || object === undefined;
};

export const createReducer = (initialState, handlers) => {
  return (state = initialState, action = null) => {
    // wrong actions, just return state
    if (isNil(action)) {
      return state;
    }
    if (!("type" in action)) {
      return state;
    }

    // look for the handler
    const handler = handlers[action.type];

    // no handler no cry
    if (isNil(handler)) {
      return state;
    }

    // execute the handler
    return handler(state, action);
  };
};
