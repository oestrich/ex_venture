import React from 'react';
import { vmlToAst } from '../utils/vmlToAst.js';
import { vmlTags, theme } from '../theme.js';
import { guid, stripVmlTags } from '../utils/utils.js';
import styled from 'styled-components';
import { connect } from 'react-redux';
import { send } from '../redux/actions/actions.js';

const ColoredSpan = styled.span`
  color: ${props => props.color};
`;

const Command = styled(ColoredSpan)`
  cursor: pointer;
  text-decoration: underline;
`;

const VmlToJsx = ({ dispatch, vmlString }) => {
  if (!vmlString) {
    return null;
  }
  // vml parser can only parse strings wrapped with any vml tag
  const markup = '{vml}' + vmlString + '{/vml}';
  const ast = vmlToAst(markup);
  const finalJsx = _astToJsx(dispatch, ast);

  return finalJsx;
};

const _astToJsx = (dispatch, ast) => {
  return ast.map(node => {
    if (node.type === 'text') {
      if (node.content.includes('\r\n')) {
        return node.content.split(/(\r\n)/).map(txt => {
          if (txt === '\r\n') {
            return <br />;
          } else {
            return txt;
          }
        });
      } else {
        return node.content;
      }
    }

    // If the node type is a 'tag', it will have children node.  Recurse on child nodes.
    if (node.type === 'tag') {
      switch (node.name) {
        case 'vml':
          return _createVmlElement(dispatch, node.children);
        case 'command':
          const cmdString = stripVmlTags(node.attrs.send);
          return _createCommandElement(dispatch, node.children, cmdString);

        // Available VML tags for color parsing are found in theme.js
        // If vml tag doesn't do anything else other than color text, it will be handled
        // by the following case statement.  Any other special cases such as the 'command'
        // case should be put in case statements above this one
        case Object.keys(vmlTags).includes(node.name) && node.name:
          return _createAllOtherVmlElements(dispatch, node.children, node.name);
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

const _createVmlElement = (dispatch, childNodes) => (
  <span key={guid()}>{_astToJsx(dispatch, childNodes)}</span>
);

const _createCommandElement = (dispatch, childNodes, cmdString) => (
  <Command
    key={guid()}
    color={theme.vml.command}
    onClick={() => {
      dispatch(send(cmdString));
    }}
  >
    {_astToJsx(dispatch, childNodes)}
  </Command>
);

const _createAllOtherVmlElements = (dispatch, childNodes, name) => (
  <ColoredSpan key={guid()} color={theme.vml[name]}>
    {_astToJsx(dispatch, childNodes)}
  </ColoredSpan>
);

export default connect()(VmlToJsx);
