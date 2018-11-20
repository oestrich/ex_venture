import React from 'react';
import ReactDOM from 'react-dom';
import App from './App.jsx';

import { Provider } from 'react-redux';
import ReduxStore from './redux/store.js';

import { channel } from './channel.js';

const reactRootElement = document.getElementById('react-root');
ReactDOM.render(
  <Provider store={ReduxStore}>
    <App />
  </Provider>,
  reactRootElement
);
