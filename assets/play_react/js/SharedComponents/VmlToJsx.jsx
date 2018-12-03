import React from 'react';
import { vmlToAst } from '../utils/vmlToAst.js';
import { vmlTags, theme } from '../theme.js';
import { guid, stripVmlTags } from '../utils/utils.js';
import styled from 'styled-components';

const ColoredSpan = styled.span`
  color: ${props => props.color};
`;

const Command = styled(ColoredSpan)`
  cursor: pointer;
`;

const VmlToJsx = ({ vmlString }) => {
  if (!vmlString) {
    return null;
  }
  // vml parser can only parse strings wrapped with any vml tag
  const markup = '{vml}' + vmlString + '{/vml}';
  const ast = vmlToAst(markup);
  const finalJsx = _astToJsx(ast);

  return finalJsx;
};

const _astToJsx = ast => {
  return ast.map(node => {
    if (node.type === 'text') {
      return node.content;
    }

    // If the node type is a 'tag', it will have children node.  Recurse on child nodes.
    if (node.type === 'tag') {
      switch (node.name) {
        case 'vml':
          return _createVmlElement(node.children);
        case 'command':
          const cmdString = stripVmlTags(node.attrs.send);
          return _createCommandElement(node.children, cmdString);

        // Available VML tags for color parsing are found in theme.js
        // If vml tag doesn't do anything else other than color text, it will be handled
        // by the following case statement.  Any other special cases such as the 'command'
        // case should be put in case statements above this one
        case Object.keys(vmlTags).includes(node.name) && node.name:
          return _createAllOtherVmlElements(node.children, node.name);
        default:
          console.log(
            `[WARNING] Unparsed VML tag: ${node.name}`,
            'Node:',
            node,
            'Full Ast: ',
            ast
          );
          break;
      }
    }
  });
};

const _createVmlElement = childNodes => (
  <span key={guid()}>{_astToJsx(childNodes)}</span>
);

const _createCommandElement = (childNodes, cmdString) => (
  <Command
    key={guid()}
    color={theme.vml.command}
    onClick={() => {
      send(cmdString);
    }}
  >
    {_astToJsx(childNodes)}
  </Command>
);

const _createAllOtherVmlElements = (childNodes, name) => (
  <ColoredSpan key={guid()} color={theme.vml[name]}>
    {_astToJsx(childNodes)}
  </ColoredSpan>
);

export default VmlToJsx;
