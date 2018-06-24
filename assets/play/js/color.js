const DEFAULT_COLORS = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"];

let defaultColor = (tag, color) => {
  let configuredColor = gameConfig["color_" + tag] || color;
  return () => {
    return `{${configuredColor}}`;
  };
};

export function defaultColorCSS(tag, color) {
  let configuredColor = gameConfig["color_" + tag] || color;
  if (DEFAULT_COLORS.includes(configuredColor)) {
    return configuredColor;
  } else {
    return `color-code-${configuredColor}`;
  }
}

function formatColor(payload) {
  let string = payload.message;

  string = string.replace(/{npc}/g, defaultColor("npc", "yellow"));
  string = string.replace(/{item}/g, defaultColor("item", "cyan"));
  string = string.replace(/{player}/g, defaultColor("player", "blue"));
  string = string.replace(/{skill}/g, defaultColor("skill", "white"));
  string = string.replace(/{quest}/g, defaultColor("quest", "yellow"));
  string = string.replace(/{room}/g, defaultColor("room", "green"));
  string = string.replace(/{say}/g, defaultColor("say", "green"));
  string = string.replace(/{shop}/g, defaultColor("shop", "magenta"));
  string = string.replace(/{hint}/g, defaultColor("hint", "cyan"));

  string = string.replace(/{exit}/g, () => {
    return `<span class='${defaultColorCSS("exit", "white")} command'>`;
  });

  string = string.replace(/{command click=false}/g, defaultColor("command", "white"));
  string = string.replace(/{exit click=false}/g, defaultColor("exit", "white"));

  string = string.replace(/{command( send='(.*)')?}/g, (_match, _fullSend, command) => {
    let color = defaultColorCSS("command", "white");
    if (payload.delink == undefined || payload.delink == false) {
      if (command != undefined) {
        return `<span class='${color} command' data-command='${command}'>`;
      } else {
        return `<span class='${color} command'>`;
      }
    } else {
      return `<span class='${color}'>`;
    }
  });

  string = string.replace(/{black}/g, "<span class='black'>")
  string = string.replace(/{red}/g, "<span class='red'>")
  string = string.replace(/{green}/g, "<span class='green'>")
  string = string.replace(/{yellow}/g, "<span class='yellow'>")
  string = string.replace(/{blue}/g, "<span class='blue'>")
  string = string.replace(/{magenta}/g, "<span class='magenta'>")
  string = string.replace(/{cyan}/g, "<span class='cyan'>")
  string = string.replace(/{white}/g, "<span class='white'>")
  string = string.replace(/{map:default}/g, "<span class='map-default'>")
  string = string.replace(/{map:blue}/g, "<span class='map-blue'>")
  string = string.replace(/{map:brown}/g, "<span class='map-brown'>")
  string = string.replace(/{map:dark-green}/g, "<span class='map-dark-green'>")
  string = string.replace(/{map:green}/g, "<span class='map-green'>")
  string = string.replace(/{map:grey}/g, "<span class='map-grey'>")
  string = string.replace(/{map:light-grey}/g, "<span class='map-light-grey'>")
  string = string.replace(/{bold}/g, "<span class='bold'>")

  // assume all other tags are custom colors
  string = string.replace(/{([\w:-]+)}/g, (_match, color) => {
    return `<span class='color-code-${color}'>`;
  });

  // Closing tags
  string = string.replace(/{\/[\w:-]+}/g, "</span>")

  return string;
}

function formatLines(string) {
  string = string.replace(/\n/g, "<br />")
  string = string.replace(/\r/g, "")
  return string;
}

export function format(payload) {
  return formatLines(formatColor(payload));
}
