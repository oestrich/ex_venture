import React, { Component } from 'react';
import { createGlobalStyle } from 'styled-components';

const GlobalStyle = createGlobalStyle`
  html, body {
   margin: 0;
   padding: 0;
   font-size: 16px;
  }
  html {
  box-sizing: border-box;
  }
  *, *:before, *:after {
  box-sizing: inherit;
  }
`;

class App extends Component {
  render() {
    return <div>REACT HELLO WORLD!!!</div>;
  }
}

export default App;
