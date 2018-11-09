import Sizzle from "sizzle"
import {Channels} from "./socket"

if (Sizzle(".chat").length > 0) {
  new Channels().join()
}