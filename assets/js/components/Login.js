import PropTypes from "prop-types";
import React from "react";
import { connect } from "react-redux";

import { Creators } from "../redux";

class Login extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      username: "",
      password: "",
    };
  }

  render() {
    const submitLogin = () => {
      this.props.login(this.state.username, this.state.password);
    };

    const loginClick = (e) => {
      e.preventDefault();
      submitLogin();
    };

    const onKeyDown = (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        submitLogin();
      }
    };

    return (
      <div className="h-full bg-white p-4 px-3 py-10 bg-gray-200 flex justify-center">
        <div className="w-full max-w-sm">
          <h1 className="text-6xl text-center">Kantele</h1>

          <form className="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
            <p className="mb-4 text-center">Welcome to Kantele, a modern text multiplayer RPG.</p>

            <p className="mb-4 text-sm text-center italic">Note: At the moment any username and password will work.</p>

            <div className="mb-4">
              <input
                autoFocus={true}
                className="input"
                id="username"
                type="text"
                placeholder="Username"
                value={this.state.username}
                onKeyDown={onKeyDown}
                onChange={(e) => {
                  this.setState({ username: e.target.value });
                }}
              />
            </div>

            <div className="mb-4">
              <input
                className="input"
                id="password"
                type="password"
                placeholder="Password"
                value={this.state.password}
                onKeyDown={onKeyDown}
                onChange={(e) => {
                  this.setState({ password: e.target.value });
                }}
              />
            </div>

            <button className="btn-primary w-full" onClick={loginClick}>
              Login
            </button>
          </form>
        </div>
      </div>
    );
  }
}

Login.propTypes = {
  login: PropTypes.func.isRequired,
};

export default connect(null, {
  login: Creators.login,
})(Login);
