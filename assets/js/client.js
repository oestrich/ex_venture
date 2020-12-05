import PropTypes from "prop-types";
import React, { Fragment } from "react";
import { connect, Provider } from "react-redux";
import { BrowserRouter as Router, Route, Redirect, Switch, withRouter } from "react-router-dom";

import { CustomTagsContext, Keys, makeReduxSocket, Prompt, Terminal } from "./kalevala";

import {
  Channels,
  CharacterSelect,
  Home,
  Inventory,
  Login,
  Map,
  Room,
  Sidebar,
  SidebarSplit,
  Vitals,
} from "./components";
import { customTags } from "./customTags";
import { Creators, getLoginStatus } from "./redux";
import { makeStore } from "./store";

const keys = new Keys();

document.addEventListener("keydown", () => {
  if (!keys.isModifierKeyPressed()) {
    let textPrompt = document.getElementById("prompt");

    if (textPrompt) {
      textPrompt.focus();
    }
  }
});

let store = makeStore();

keys.on(["Alt", "ArrowUp"], (e) => {
  e.preventDefault();
  store.dispatch(Creators.moveNorth());
});

keys.on(["Alt", "ArrowDown"], (e) => {
  e.preventDefault();
  store.dispatch(Creators.moveSouth());
});

keys.on(["Alt", "ArrowLeft"], (e) => {
  e.preventDefault();
  store.dispatch(Creators.moveWest());
});

keys.on(["Alt", "ArrowRight"], (e) => {
  e.preventDefault();
  store.dispatch(Creators.moveEast());
});

let SocketProvider = class SocketProvider extends React.Component {
  constructor(props) {
    super(props);

    const { history } = props;

    this.socket = makeReduxSocket("/socket", store, { history });
    this.socket.join();
  }

  render() {
    return <Fragment>{this.props.children}</Fragment>;
  }
};

SocketProvider.propTypes = {
  children: PropTypes.node,
  history: PropTypes.object.isRequired,
};

SocketProvider = withRouter(SocketProvider);

let ValidateLoggedIn = class ValidateLoggedIn extends React.Component {
  render() {
    if (this.props.loggedIn) {
      return null;
    } else {
      return <Redirect to="/" />;
    }
  }
};

ValidateLoggedIn.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
};

const mapStateToProps = (state) => {
  const loggedIn = getLoginStatus(state);
  return { loggedIn };
};

ValidateLoggedIn = connect(mapStateToProps)(ValidateLoggedIn);

const Client = () => {
  return (
    <div className="relative">
      <ValidateLoggedIn />
      <div className="flex flex-row h-full">
        <Sidebar side="left" width="w-1/4 max-w-xs">
          <h3 className="text-white text-3xl text-center pt-2">Kantele</h3>
          <Vitals />
          <SidebarSplit />
          <Inventory />
        </Sidebar>
        <div className="flex flex-col flex-grow w-1/2 overflow-y-scroll">
          <Sidebar side="top" width="w-full">
            <Room />
          </Sidebar>
          <CustomTagsContext.Provider value={customTags}>
            <Terminal />
          </CustomTagsContext.Provider>
          <Prompt />
        </div>
        <Sidebar side="right" width="w-1/4 max-w-xs">
          <Map />
          <SidebarSplit />
          <Channels />
        </Sidebar>
      </div>
    </div>
  );
};

export class App extends React.Component {
  render() {
    return (
      <Provider store={store}>
        <Router>
          <SocketProvider>
            <Switch>
              <Route path="/login/character">
                <CharacterSelect />
              </Route>
              <Route path="/login">
                <Login />
              </Route>
              <Route path="/client">
                <Client />
              </Route>
              <Route>
                <Home />
              </Route>
            </Switch>
          </SocketProvider>
        </Router>
      </Provider>
    );
  }
}
