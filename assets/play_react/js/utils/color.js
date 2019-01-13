window.gameConfig = {};

const DEFAULT_COLORS = [
  'black',
  'red',
  'green',
  'yellow',
  'blue',
  'magenta',
  'cyan',
  'white'
];

let defaultColor = (tag, color) => {
  let configuredColor = gameConfig['color_' + tag] || color;
  return () => {
    return `{${configuredColor}}`;
  };
};

export function defaultColorCSS(tag, color) {
  let configuredColor = gameConfig['color_' + tag] || color;
  if (DEFAULT_COLORS.includes(configuredColor)) {
    return configuredColor;
  } else {
    return `color-code-${configuredColor}`;
  }
}

function formatColor(payload) {
  let string = payload;

  string = string.replace(/{npc}/g, defaultColor('npc', 'yellow'));
  string = string.replace(/{item}/g, defaultColor('item', 'cyan'));
  string = string.replace(/{player}/g, defaultColor('player', 'blue'));
  string = string.replace(/{skill}/g, defaultColor('skill', 'white'));
  string = string.replace(/{quest}/g, defaultColor('quest', 'yellow'));
  string = string.replace(/{room}/g, defaultColor('room', 'green'));
  string = string.replace(/{zone}/g, defaultColor('zone', 'white'));
  string = string.replace(/{say}/g, defaultColor('say', 'green'));
  string = string.replace(/{shop}/g, defaultColor('shop', 'magenta'));
  string = string.replace(/{hint}/g, defaultColor('hint', 'cyan'));
  string = string.replace(/{error}/g, defaultColor('error', 'red'));

  string = string.replace(/{exit}/g, () => {
    return `<span class='${defaultColorCSS('exit', 'white')} command'>`;
  });

  string = string.replace(
    /{command click=false}/g,
    defaultColor('command', 'white')
  );
  string = string.replace(/{exit click=false}/g, defaultColor('exit', 'white'));
  string = string.replace(/{link click=false}/g, defaultColor('link', 'white'));

  string = string.replace(
    /{command( send='(.*)')?}/g,
    (_match, _fullSend, command) => {
      let color = defaultColorCSS('command', 'white');
      if (payload.delink == undefined || payload.delink == false) {
        if (command != undefined) {
          return `<span class='${color} command' style='color:${color};text-decoration:underline;cursor:pointer'  onclick='send("${command}")' data-command='${command}'>`;
        } else {
          return `<span class='${color} command'>`;
        }
      } else {
        return `<span class='${color}'>`;
      }
    }
  );

  string = string.replace(/{link}(.*){\/link}/g, (_match, link) => {
    let color = defaultColorCSS('link', 'white');
    if (payload.delink == undefined || payload.delink == false) {
      return `<a href='${link}' class='${color} link' target='_blank'>${link}</a>`;
    } else {
      return `<span class='${color}'>${link}</span>`;
    }
  });

  string = string.replace(/{black}/g, "<span class='black'>");
  string = string.replace(/{red}/g, "<span class='red'>");
  string = string.replace(/{green}/g, "<span class='green'>");
  string = string.replace(/{yellow}/g, "<span class='yellow'>");
  string = string.replace(/{blue}/g, "<span class='blue'>");
  string = string.replace(/{magenta}/g, "<span class='magenta'>");
  string = string.replace(/{cyan}/g, "<span class='cyan'>");
  string = string.replace(/{white}/g, "<span class='white'>");
  string = string.replace(/{brown}/g, "<span class='brown'>");
  string = string.replace(/{dark-green}/g, "<span class='dark-green'>");
  string = string.replace(/{grey}/g, "<span class='grey'>");
  string = string.replace(/{light-grey}/g, "<span class='light-grey'>");
  string = string.replace(/{bold}/g, "<span class='bold'>");

  // assume all other tags are custom colors
  string = string.replace(/{([\w:-]+)}/g, (_match, color) => {
    return `<span class='color-code-${color}'>`;
  });

  // Closing tags
  string = string.replace(/{\/[\w:-]+}/g, '</span>');

  // escaped special characters
  string = string.replace(/\\\[/g, '[');
  string = string.replace(/\\]/g, ']');
  string = string.replace(/\\{/g, '{');
  string = string.replace(/\\}/g, '}');

  return string;
}

function formatLines(string) {
  string = string.replace(/\n/g, '<br />');
  string = string.replace(/\r/g, '');
  return string;
}

export function format(payload) {
  return formatLines(formatColor(payload));
}

export function stripColor(payload) {
  return payload.replace(/{\/?[\w:-]+}/g, '');
}
