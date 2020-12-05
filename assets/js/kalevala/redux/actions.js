export const Types = {
  PROMPT_CLEAR: "PROMPT_CLEAR",
  PROMPT_HISTORY_ADD: "PROMPT_HISTORY_ADD",
  PROMPT_HISTORY_SCROLL_BACKWARD: "PROMPT_HISTORY_SCROLL_BACKWARD",
  PROMPT_HISTORY_SCROLL_FORWARD: "PROMPT_HISTORY_SCROLL_FORWARD",
  PROMPT_SET_CURRENT_TEXT: "PROMPT_SET_CURRENT_TEXT",
  SOCKET_CLEAR_VERBS: "SOCKET_CLEAR_VERBS",
  SOCKET_CONNECTED: "SOCKET_CONNECTED",
  SOCKET_DISCONNECTED: "SOCKET_DISCONNECTED",
  SOCKET_GET_CONTEXT_VERBS: "SOCKET_GET_CONTEXT_VERBS",
  SOCKET_RECEIVED_EVENT: "SOCKET_RECEIVED_EVENT",
  SOCKET_SEND_EVENT: "SOCKET_SEND_EVENT",
};

export const Creators = {
  promptClear: () => {
    return { type: Types.PROMPT_CLEAR };
  },
  promptHistoryAdd: () => {
    return { type: Types.PROMPT_HISTORY_ADD };
  },
  promptHistoryScrollBackward: () => {
    return { type: Types.PROMPT_HISTORY_SCROLL_BACKWARD };
  },
  promptHistoryScrollForward: () => {
    return { type: Types.PROMPT_HISTORY_SCROLL_FORWARD };
  },
  promptSetCurrentText: (text) => {
    return { type: Types.PROMPT_SET_CURRENT_TEXT, data: { text } };
  },
  socketConnected: (socket) => {
    return { type: Types.SOCKET_CONNECTED, data: { socket } };
  },
  socketDisconnected: () => {
    return { type: Types.SOCKET_DISCONNECTED };
  },
  socketGetContextVerbs: (context, type, id) => {
    return (dispatch, getState) => {
      const { socket } = getState().socket;

      dispatch({
        type: Types.SOCKET_CLEAR_VERBS,
        data: { context, type, id },
      });

      socket.send({
        topic: `Context.Lookup`,
        data: { context, type, id },
      });
    };
  },
  socketReceivedEvent: (event, eventHandlerArguments) => {
    return (dispatch, getState, { eventHandlers }) => {
      const eventHandler = eventHandlers[event.topic];

      if (eventHandler) {
        eventHandler(dispatch, getState, event, eventHandlerArguments);
      }

      if (event.topic == "system/multiple") {
        event.data.forEach((event) => {
          dispatch(Creators.socketReceivedEvent(event, eventHandlerArguments));
        });

        return;
      }

      dispatch({ type: Types.SOCKET_RECEIVED_EVENT, data: { event } });
    };
  },
  socketSendEvent: (event) => {
    return (dispatch, getState) => {
      const { socket } = getState().socket;

      socket.send(event);

      dispatch({ type: Types.SOCKET_SEND_EVENT, data: { event } });
    };
  },
};
