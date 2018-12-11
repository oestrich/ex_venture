import React from 'react';
import ReactDOM from 'react-dom';
import App from './app.jsx';
import { Provider } from 'react-redux';
import ReduxStore from './redux/store.js';

const reactRootElement = document.getElementById('react-root');
ReactDOM.render(
  <Provider store={ReduxStore}>
    <App />
  </Provider>,
  reactRootElement
);
