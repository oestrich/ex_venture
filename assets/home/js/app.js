import '../css/base.scss';
import Sizzle from 'sizzle';
import { Channels } from './socket.js';
import 'phoenix_html';

if (Sizzle('.chat').length > 0) {
  new Channels().join();
}
