// vmlTags object serves two purposes:
// 1. To map colors to vml tags
// 2. Serve as a list of available tags that can be parsed.
//    If a tag is not in the object, the VmlToJsx component will not parse it.
export const vmlTags = {
  exit: 'white',
  npc: '#F2BD78',
  item: '#4DFFFF',
  player: '#4DFFFF',
  skill: 'white',
  quest: 'yellow',
  room: 'green',
  zone: 'white',
  say: '#84E1E1',
  shop: '#FFEE66',
  hint: 'cyan',
  command: 'white',
  error: 'red',
  red: '#FA8F8F',
  white: 'white'
};
export const theme = {
  vml: vmlTags,
  text: '#C4E9E9',
  font: 'Lucida Grande, Lucida Sans Unicode, Lucida Sans, Geneva, Verdana',
  bgPrimary: '#6177C8',
  bgSecondary: '#435AAF',
  statusBar: {
    hp: '#FA8F8F',
    sp: '#3845FF',
    ep: '#B6FFAD'
  }
};
