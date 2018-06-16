/**
 * Map helper functions
 */
export default class OverworldMap {
  constructor(map) {
    let groupedMap = map.reduce((acc, val) => {
      if (acc[val.y] == undefined) {
        acc[val.y] = [];
      }

      acc[val.y].push(val);

      return acc;
    }, []);

    this.overworld = groupedMap.map((row) => {
      return row.sort((a, b) => { return a.x - b.x; });
    });
  }

  updateCell(x, y, attrs) {
    this.overworld[y][x].s = attrs.s;
    this.overworld[y][x].c = attrs.c;
  }

  rows(fun) {
    return this.overworld.map(fun);
  }

  toJSON() {
    let flattenedMap = this.overworld.reduce((acc, val) => acc.concat(val), []);
    return JSON.stringify(flattenedMap);
  }
}
