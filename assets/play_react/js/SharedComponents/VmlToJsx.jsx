import React from 'react';
import { vmlToAst } from '../utils/vmlToAst.js';
import { vmlTags, theme } from '../theme.js';
import { guid } from '../utils/utils.js';
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
          return <span key={guid()}>{_astToJsx(node.children)}</span>;
        case 'command':
          // strip away any vml tags from command being sent to server
          const commandString = node.attrs.send
            ? node.attrs.send.replace(/{.*?}/g, '')
            : '';
          return (
            <Command
              key={guid()}
              color={theme.vml.command}
              onClick={() => {
                send(commandString);
              }}
            >
              {_astToJsx(node.children)}
            </Command>
          );
        // Available VML tags for color parsing are found in theme.js
        // If vml tag doesn't do anything else other than color text, it will be handled
        // by the following case statement.  Any other special cases such as the 'command'
        // case should be put in case statements above this one
        case Object.keys(vmlTags).includes(node.name) && node.name:
          return (
            <ColoredSpan key={guid()} color={theme.vml[node.name]}>
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
