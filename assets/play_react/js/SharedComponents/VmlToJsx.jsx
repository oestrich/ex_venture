import React from 'react';
import { vmlToAst } from '../utils/vmlToJsx.js';
import { vmlTags, theme } from '../theme.js';
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
    if (node.type === 'tag') {
      switch (node.name) {
        case 'vml':
          return <span>{_astToJsx(node.children)}</span>;
        // Available VML tags for color parsing are found in theme.js
        case 'command':
          return (
            <Command
              color={theme.vml.command}
              onClick={() => {
                send(node.command);
              }}
            >
              {_astToJsx(node.children)}
            </Command>
          );
        case Object.keys(vmlTags).includes(node.name) && node.name:
          return (
            <ColoredSpan color={theme.vml[node.name]}>
              {_astToJsx(node.children)}
            </ColoredSpan>
          );
        default:
          console.log('Unparsed VML tag: ', node.name);
          break;
      }
    }
  });
};

export default VmlToJsx;
