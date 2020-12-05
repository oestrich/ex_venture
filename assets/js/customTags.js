import React from "react";
import { renderTags } from "./kalevala/components/Terminal";

import { CommandWrapper, ItemWrapper } from "./components";

const CharacterTag = (tag) => {
  return (
    <span className="tooltip-hover inline-block">
      {renderTags(tag.children)}
      <div className="tooltip font-sans">
        <h3 className="text-xl">{tag.attributes.name}</h3>
        <p>{tag.attributes.description}</p>
      </div>
    </span>
  );
};

const ItemInstanceTag = (tag) => {
  return <ItemWrapper attributes={tag.attributes}>{renderTags(tag.children)}</ItemWrapper>;
};

const CommandTag = (tag) => {
  return <CommandWrapper send={tag.attributes.send}>{renderTags(tag.children)}</CommandWrapper>;
};

export const customTags = {
  character: CharacterTag,
  "item-instance": ItemInstanceTag,
  command: CommandTag,
};
