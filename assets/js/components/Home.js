import PropTypes from "prop-types";
import React from "react";
import { connect } from "react-redux";
import { Link } from "react-router-dom";

import { getLoginActive } from "../redux";

let Home = class Home extends React.Component {
  renderLogin() {
    if (this.props.loginActive) {
      return (
        <Link
          className="inline-block text-sm px-4 py-2 leading-none border rounded text-white border-white hover:border-transparent hover:text-teal-500 hover:bg-white"
          to="/login"
        >
          Login
        </Link>
      );
    } else {
      return (
        <a className="inline-block text-sm px-4 py-2 leading-none border rounded text-gray-200 border-gray-200 hover:border-transparent hover:text-gray-500 hover:bg-white">
          Login
        </a>
      );
    }
  }

  render() {
    return (
      <div className="bg-gray-200">
        <nav className="flex items-center justify-between flex-wrap bg-teal-500 p-4">
          <div className="container mx-auto flex flex-wrap items-center">
            <div className="flex items-center flex-shrink-0 text-white w-1/2">
              <Link to="/" className="text-white no-underline hover:text-white hover:no-underline pl-2">
                <span className="font-semibold text-xl tracking-tight">Kantele</span>
              </Link>
            </div>

            <div className="flex items-center content-center w-1/2 justify-end">{this.renderLogin()}</div>
          </div>
        </nav>

        <div className="container mx-auto mt-4 px-4 sm:px-0 h-screen">
          <div className="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
            <p className="text-xl sm:text-4xl">Kantele is a multiplayer text adventure.</p>
            <p>
              This is the sample game for{" "}
              <a
                className="underline text-gray-700"
                href="https://github.com/oestrich/kalevala"
                rel="noreferrer"
                target="_blank"
              >
                Kalevala
              </a>
              , a world building toolkit written in Elixir.
            </p>
          </div>
        </div>
      </div>
    );
  }
};

Home.propTypes = {
  loginActive: PropTypes.bool,
};

const mapStateToProps = (state) => {
  const loginActive = getLoginActive(state);
  return { loginActive };
};

export default Home = connect(mapStateToProps)(Home);
