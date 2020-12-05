import parseText, { Line, LineBreak, NewLine, parseTag } from "./parseText";

describe("breaking apart a single tag", () => {
  test("has no line breaks", () => {
    let tag = {
      name: "color",
      attributes: { foreground: "red" },
      children: ["text"],
    };

    let tags = parseTag(tag);

    let expected = [
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "text",
          },
        ],
      },
    ];

    expect(tags).toEqual(expected);
  });

  test("one line break", () => {
    let tag = {
      name: "color",
      attributes: { foreground: "red" },
      children: ["one\nline"],
    };

    let tags = parseTag(tag);

    expect(tags).toEqual([
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "one",
          },
        ],
      },
      LineBreak,
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "line",
          },
        ],
      },
    ]);
  });

  test("many line breaks", () => {
    let tag = {
      name: "color",
      attributes: { foreground: "red" },
      children: ["one line\ntwo line\nthree line"],
    };

    let tags = parseTag(tag);

    expect(tags).toEqual([
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "one line",
          },
        ],
      },
      LineBreak,
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "two line",
          },
        ],
      },
      LineBreak,
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "three line",
          },
        ],
      },
    ]);
  });

  test("multiple children", () => {
    let tag = {
      name: "color",
      attributes: { foreground: "red" },
      children: ["one\nline", "two\nline"],
    };

    let tags = parseTag(tag);

    expect(tags).toEqual([
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "one",
          },
        ],
      },
      LineBreak,
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "line",
          },
          {
            id: expect.anything(),
            name: "string",
            text: "two",
          },
        ],
      },
      LineBreak,
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "line",
          },
        ],
      },
    ]);
  });

  test("tags as children", () => {
    let tag = {
      name: "color",
      attributes: { foreground: "red" },
      children: [
        "one\nline",
        {
          name: "color",
          attributes: { foreground: "green" },
          children: ["two\nline"],
        },
      ],
    };

    let tags = parseTag(tag);

    expect(tags).toEqual([
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "one",
          },
        ],
      },
      LineBreak,
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "string",
            text: "line",
          },
          {
            id: expect.anything(),
            name: "color",
            attributes: { foreground: "green" },
            children: [
              {
                id: expect.anything(),
                name: "string",
                text: "two",
              },
            ],
          },
        ],
      },
      LineBreak,
      {
        id: expect.anything(),
        name: "color",
        attributes: { foreground: "red" },
        children: [
          {
            id: expect.anything(),
            name: "color",
            attributes: { foreground: "green" },
            children: [
              {
                id: expect.anything(),
                name: "string",
                text: "line",
              },
            ],
          },
        ],
      },
    ]);
  });
});

describe("processing text output from the game into separate lines", () => {
  test("breaks strings into separate lines", () => {
    let lines = parseText(["new lines \n of text"]);

    expect(lines).toEqual([
      new Line(
        {
          id: expect.anything(),
          name: "string",
          text: "new lines ",
        },
        expect.anything(),
      ),
      new NewLine(expect.anything()),
      new Line(
        {
          id: expect.anything(),
          name: "string",
          text: " of text",
        },
        expect.anything(),
      ),
    ]);
  });

  test("does not eat double newlines", () => {
    let lines = parseText(["new lines \n\n of text"]);

    expect(lines).toEqual([
      new Line(
        {
          id: expect.anything(),
          name: "string",
          text: "new lines ",
        },
        expect.anything(),
      ),
      new NewLine(expect.anything()),
      new NewLine(expect.anything()),
      new Line(
        {
          id: expect.anything(),
          name: "string",
          text: " of text",
        },
        expect.anything(),
      ),
    ]);
  });

  test("more complex version", () => {
    let lines = parseText(["new lines \n of text", [[" extra"], " \ntext"]]);

    expect(lines).toEqual([
      new Line(
        {
          id: expect.anything(),
          name: "string",
          text: "new lines ",
        },
        expect.anything(),
      ),
      new NewLine(expect.anything()),
      new Line(
        [
          {
            id: expect.anything(),
            name: "string",
            text: " of text",
          },
          {
            id: expect.anything(),
            name: "string",
            text: " extra",
          },
          {
            id: expect.anything(),
            name: "string",
            text: " ",
          },
        ],
        expect.anything(),
      ),
      new NewLine(expect.anything()),
      new Line(
        {
          id: expect.anything(),
          name: "string",
          text: "text",
        },
        expect.anything(),
      ),
    ]);
  });

  test("breaks tags into separate lines", () => {
    let lines = parseText([
      {
        name: "color",
        attributes: { foreground: "red" },
        children: [
          "new lines \n of text",
          {
            name: "color",
            attributes: { foreground: "green" },
            children: ["separate\ncolor"],
          },
          "back to red",
        ],
      },
    ]);

    expect(lines).toEqual([
      new Line(
        {
          id: expect.anything(),
          name: "color",
          attributes: { foreground: "red" },
          children: [
            {
              id: expect.anything(),
              name: "string",
              text: "new lines ",
            },
          ],
        },
        expect.anything(),
      ),
      new NewLine(expect.anything()),
      new Line(
        {
          id: expect.anything(),
          name: "color",
          attributes: { foreground: "red" },
          children: [
            {
              id: expect.anything(),
              name: "string",
              text: " of text",
            },
            {
              id: expect.anything(),
              name: "color",
              attributes: { foreground: "green" },
              children: [
                {
                  id: expect.anything(),
                  name: "string",
                  text: "separate",
                },
              ],
            },
          ],
        },
        expect.anything(),
      ),
      new NewLine(expect.anything()),
      new Line(
        {
          id: expect.anything(),
          name: "color",
          attributes: { foreground: "red" },
          children: [
            {
              id: expect.anything(),
              name: "color",
              attributes: { foreground: "green" },
              children: [
                {
                  id: expect.anything(),
                  name: "string",
                  text: "color",
                },
              ],
            },
            {
              id: expect.anything(),
              name: "string",
              text: "back to red",
            },
          ],
        },
        expect.anything(),
      ),
    ]);
  });
});
