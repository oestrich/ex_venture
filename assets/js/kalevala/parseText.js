const arrayWrap = (data) => {
  if (!(data instanceof Array)) {
    data = [data];
  }

  return data;
};

const generateTagId = () => {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
};

class Line {
  constructor(text, id) {
    this.id = id || generateTagId();
    this.children = arrayWrap(text);
  }
}

export class NewLine {
  constructor(id) {
    this.id = id || generateTagId();
  }
}

const LineBreak = new NewLine();

const splitString = (string) => {
  let strings = string
    .split("\n")
    .map((s) => [LineBreak, s])
    .flat()
    .slice(1);

  let reducer = (context, string) => {
    if (string === LineBreak) {
      context.strings = context.strings.concat([context.current, LineBreak]);
      context.current = [];
    } else {
      context.current.push(string);
    }

    return context;
  };

  let context = strings.reduce(reducer, { strings: [], current: [] });

  return context.strings.concat([context.current]);
};

const flattenChildren = (children) => {
  let reducer = (context, child) => {
    if (child === LineBreak) {
      context.children = context.children.concat([context.current, LineBreak]);
      context.current = [];
    } else {
      context.current = context.current.concat(arrayWrap(child));
    }

    return context;
  };

  let context = children.reduce(reducer, { children: [], current: [] });
  return context.children.concat([context.current]);
};

const parseTag = (tag) => {
  let children;

  if (typeof tag === "string") {
    return splitString(tag).map((strings) => {
      if (strings instanceof Array) {
        return strings.map((string) => {
          return { id: generateTagId(), name: "string", text: string };
        });
      }

      // LineBreak
      return strings;
    });
  }

  if (tag instanceof Array) {
    return tag.map(parseTag).flat();
  }

  children = tag.children.map(parseTag).flat();
  return flattenChildren(children).map((children) => {
    if (children === LineBreak) {
      return LineBreak;
    }

    return { ...tag, id: generateTagId(), children: arrayWrap(children) };
  });
};

const parseText = (input) => {
  let children = arrayWrap(input).map(parseTag).flat();

  return flattenChildren(children)
    .filter((tag) => {
      return !(tag.length == 1 && tag[0].name == "string" && tag[0].text == "");
    })
    .map((tag) => {
      if (tag == LineBreak) {
        return new NewLine();
      } else {
        return new Line(tag);
      }
    });
};

export default parseText;
export { Line, LineBreak, parseTag };
