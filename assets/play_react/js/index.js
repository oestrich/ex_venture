import React from 'react';
import ReactDOM from 'react-dom';
import App from './App.jsx';

import { Provider } from 'react-redux';
import ReduxStore from './redux/store.js';

// FIX: For testing phoenix conx
import { channel } from './socket.js';
channel.on('gmcp', data => {
  console.log('[Channel: GMCP]', data);
});

channel.on('option', data => {
  console.log('[Channel: OPTION', data);
});
channel.on('prompt', data => {
  console.log('[Channel: PROMPT', data);
});
channel.on('echo', data => {
  console.log('[Channel: ECHO', data);
});
channel.on('disconnect', data => {
  console.log('[Channel: DISCONNECT', data);
});
console.log('channel', channel);
window.channel = channel;

const reactRootElement = document.getElementById('react-root');
ReactDOM.render(
  <Provider store={ReduxStore}>
    <App />
  </Provider>,
  reactRootElement
);
