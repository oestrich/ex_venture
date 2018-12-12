// Ex_Venture uses a single Phoenix channel for websocket communication.
// The single channel is split into different sub events
// such as GMCP, OPTION, DISCONNECT, PROMPT, ECHO.
// GMCP is further split into sub channels or 'modules'.
// Ex_Venture's GMCP protocol can be found here: https://exventure.org/game/gmcp/
// All the channel listener's are set up in the action creators at ./redux/actions/actions.js

import { Socket } from 'phoenix';
import { guid } from './utils/utils.js';

// Character token is injected into markup by server on initial /play-react route render
const characterToken = body.getAttribute('data-character-token');
const socket = new Socket('/socket', {
  params: {
    token: characterToken
  },
  logger: (kind, msg, data) => console.log(`[PHX SOCKET] ${kind}: ${msg}`, data)
});
socket.connect();
let channel = socket.channel('telnet:' + 'webclient:' + guid(), {});
channel.join();

// Expose the channel object and a send function to browser window for development purposes.
// TODO: All messages sent to server should go through redux actions instead of this temporary
// window.send function
// const send = message => {
//   channel.push('recv', { message: message });
// };
// window.send = send;
// window.channel = channel;
// console.log(
//   '[DEVELOPMENT MODE]: You can send messages to the server with window.send function'
// );

export { channel };
