import '../css/base.scss';
import '../css/vendor/bootstrap.css';
import '../css/vendor/fontawesome.css';
import Sizzle from "sizzle"
import {Channels} from "./socket"

if (Sizzle(".chat").length > 0) {
  new Channels().join()
}