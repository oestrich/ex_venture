import { Creators } from "./redux";

export class Socket {
  constructor(path) {
    this.path = path;
  }

  connect() {
    const protocol = location.protocol == "https:" ? "wss:" : "ws:";

    this.socket = new WebSocket(`${protocol}//${location.host}${this.path}`);

    this.socket.onmessage = (message) => {
      let event = JSON.parse(message.data);
      if (this.onEvent) {
        this.onEvent(event);
      }
    };

    this.socket.onopen = (e) => {
      console.log("Socket opened");

      if (this.onOpen) {
        this.onOpen(e);
      }
    };

    this.socket.onclose = (e) => {
      console.log("Socket closed");

      clearInterval(this.pingTimeout);

      if (this.onClose) {
        this.onClose(e);
      }
    };

    this.socket.onerror = (e) => {
      console.log("Socket error");

      if (this.onError) {
        this.onError(e);
      }
    };

    this.pingTimeout = setInterval(() => {
      this.send({ topic: "system/ping" });
    }, 5000);
  }

  send(event) {
    if (this.socket.readyState != WebSocket.OPEN) {
      console.log("Trying to send an event but the socket is closed", event);
      return;
    }

    this.socket.send(JSON.stringify(event));
  }

  onEvent(fun) {
    this.onEvent = fun;
  }

  onOpen(fun) {
    this.onOpen = fun;
  }

  onClose(fun) {
    this.onClose = fun;
  }

  onError(fun) {
    this.onError = fun;
  }
}

export const makeReduxSocket = (path, store, eventHandlerArguments = {}) => {
  const socket = new Socket(path);

  return new ReduxSocket(socket, {
    connected: (socket) => {
      store.dispatch(Creators.socketConnected(socket));
    },
    disconnected: () => {
      store.dispatch(Creators.socketDisconnected());
    },
    receivedEvent: (event) => {
      store.dispatch(Creators.socketReceivedEvent(event, eventHandlerArguments));
    },
  });
};

export class ReduxSocket {
  constructor(socket, creators) {
    this.socket = socket;
    this.creators = creators;
  }

  join() {
    this.socket.connect();
    this.connect();
  }

  connect() {
    this.socket.onEvent((event) => {
      this.creators.receivedEvent(event);
    });

    this.socket.onOpen(() => {
      this.creators.connected(this);
    });

    this.socket.onClose(() => {
      this.creators.disconnected();
    });

    this.socket.onError(() => {
      this.creators.disconnected();
    });
  }

  send(event) {
    this.socket.send(event);
  }
}
