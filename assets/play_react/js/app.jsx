import React, { Component } from 'react';
import { connect } from 'react-redux';
import { createGlobalStyle } from 'styled-components';
import GameContainer from './GameContainer/index.jsx';
import { initSubscriptions } from './redux/actions/actions.js';

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
  constructor(props) {
    super(props);
  }
  componentDidMount() {
    this.props.dispatch(initSubscriptions());
  }
  render() {
    return <GameContainer />;
  }
}

export default connect()(App);
