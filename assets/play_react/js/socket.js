// Initialize phoenix websocket connection
import { Socket } from 'phoenix';

const characterToken = body.getAttribute('data-character-token');
const socket = new Socket('/socket', { params: { token: characterToken } });
socket.connect();

export default socket;
