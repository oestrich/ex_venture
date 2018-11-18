// Initialize phoenix websocket connection
import { Socket } from 'phoenix';
import { guid } from './utils.js';

const characterToken = body.getAttribute('data-character-token');
const socket = new Socket('/socket', {
  params: {
    token: characterToken
  }
});
socket.connect();
let channel = socket.channel('telnet:' + 'webclient:' + guid(), {});
channel.join();
console.log('channel joined');

export { channel };
