import React from 'react';
import { vmlToAst } from '../utils/vmlToJsx.js';

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
        case [
          'npc',
          'item',
          'player',
          'skill',
          'quest',
          'room',
          'zone',
          'say',
          'shop',
          'hint',
          'error',
          'white',
          'red'
        ].includes(node.name) && node.name:
          return (
            <span style={{ color: 'white' }}>{_astToJsx(node.children)}</span>
          );
        case 'command':
          return (
            <span
              onClick={() => {
                send(node.command);
              }}
              style={{ color: 'white' }}
            >
              {_astToJsx(node.children)}
            </span>
          );
        default:
          console.log('Unparsed VML tag: ', node.name);
          break;
      }
    }
  });
};

export default VmlToJsx;
