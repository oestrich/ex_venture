import "../css/app.scss"
import "admin-lte"
import "bootstrap"
import "phoenix_html"


import "./socket.js"
import "./npcs.js"

import Effects from "./effects.jsx"
import Script from "./scripts.jsx"
import WorldMap from "./world_map.jsx"
import WorldMapExits from "./world_map_exits.jsx"

window.Components = {
  Effects,
  Script,
  WorldMap,
  WorldMapExits,
}
// Enable tooltips
$(function () {
  $('[data-toggle="tooltip"]').tooltip();
})

import React from "react"
import ReactDOM from "react-dom"

/**
 * ReactPhoenix
 *
 * Copied from https://github.com/geolessel/react-phoenix/blob/master/src/react_phoenix.js
 */

class ReactPhoenix {
  static init() {
    const elements = document.querySelectorAll('[data-react-class]')
    Array.prototype.forEach.call(elements, e => {
      const targetId = document.getElementById(e.dataset.reactTargetId)
      const targetDiv = targetId ? targetId : e
      const reactProps = e.dataset.reactProps ? e.dataset.reactProps : "{}"
      const reactElement = React.createElement(eval(e.dataset.reactClass), JSON.parse(reactProps))
      ReactDOM.render(reactElement, targetDiv)
    })
  }
}

document.addEventListener("DOMContentLoaded", e => {
  ReactPhoenix.init();
})
