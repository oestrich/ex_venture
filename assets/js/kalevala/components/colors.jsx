const basicColorCodes = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"];

/**
 * Parse 256 color into rgb
 */
export const parse256Color = (color) => {
  // memoize colors to the window
  if (window.colorizer256Colors == undefined) {
    memoize256Colors();
  }

  switch (true) {
    case color < 8:
      return basicColorCodes[color];

    case color < 16:
      return basicColorCodes[color - 8];

    default:
      return window.colorizer256Colors[color];
  }
};

const toHex = (decimal) => {
  let hex = decimal.toString(16);
  if (hex.length < 2) {
    hex = "0" + hex;
  }
  return hex;
};

const rgbToHex = (r, g, b) => {
  return "#" + toHex(r) + toHex(g) + toHex(b);
};

// Mostly from Anser, https://github.com/IonicaBizau/anser
const memoize256Colors = () => {
  window.colorizer256Colors = [];

  // Index 0..15 : System color
  for (let i = 0; i < 16; ++i) {
    window.colorizer256Colors.push(null);
  }

  // Index 16..231 : RGB 6x6x6
  // https://gist.github.com/jasonm23/2868981#file-xterm-256color-yaml
  let levels = [0, 95, 135, 175, 215, 255];
  for (let r = 0; r < 6; ++r) {
    for (let g = 0; g < 6; ++g) {
      for (let b = 0; b < 6; ++b) {
        window.colorizer256Colors.push(rgbToHex(levels[r], levels[g], levels[b]));
      }
    }
  }

  // Index 232..255 : Grayscale
  let level = 8;
  for (let i = 0; i < 24; ++i, level += 10) {
    window.colorizer256Colors.push(rgbToHex(level, level, level));
  }
};
