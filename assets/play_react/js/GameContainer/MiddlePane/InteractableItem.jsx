import React from 'react';
import styled, { css } from 'styled-components';
import VmlParser from '../../SharedComponents/VmlParser.jsx';
import { theme } from '../../theme.js';
import { send } from '../../redux/actions/actions.js';
import { ToolTipController, Select } from 'react-tooltip-controller';

const InteractableItemContainer = styled.div`
  display: inline-block;
  box-shadow: ${props => (props.selected ? '0 0px 6px 1px #000000' : null)};
  background: ${props => (props.selected ? 'wheat' : null)};
  border-radius: ${props => (props.selected ? '5px' : null)};
  padding-left: ${props => (props.selected ? '5px' : null)};
  padding-right: ${props => (props.selected ? '5px' : null)};
`;

const ToolTip = styled.div`
  color: #ff6b00;
  background-color: #fff;
  box-shadow: 0px 3px 4px 0px #ebebeb;
  border-radius: 3px;
`;

const ColoredSpan = styled.span`
  color: ${props => props.color};
  display: inline-block;
`;

class InteractableItem extends React.Component {
  constructor(props) {
    super(props);
    this.state = { selected: '' };
  }
  render() {
    const { items, itemType } = this.props;

    return items.map((item, idx) => (
      <ToolTipController
        key={idx}
        id={`${itemType}-tooltip-${idx}`}
        returnState={isTooltipShowing => {
          if (isTooltipShowing) {
            this.setState(
              { selected: `${itemType}-tooltip-${idx}` },
              function() {
                if (itemType !== 'item') {
                  send(`target ${item.name}`);
                }
              }
            );
          } else if (this.state.selected === `${itemType}-tooltip-${idx}`) {
            this.setState({ selected: '' });
          }
        }}
        detect="click"
        offsetX={200}
        offsetY={2}
      >
        <Select>
          <InteractableItemContainer
            selected={
              this.state.selected === `${itemType}-tooltip-${idx}`
                ? true
                : false
            }
          >
            {/* itemType: items are a one off case, they can't be parsed by VML parser because GMCP doesnt give it color tags */}
            {itemType === 'item' ? (
              <ColoredSpan color={theme.vml.item} key={item.id}>
                {item.name}
                {idx === items.length - 1 ? (
                  <ColoredSpan color={theme.text}>. </ColoredSpan>
                ) : (
                  <ColoredSpan color={theme.text}>, </ColoredSpan>
                )}
              </ColoredSpan>
            ) : (
              <VmlParser
                vmlString={item.status_line ? item.status_line : item.name}
              />
            )}
          </InteractableItemContainer>
        </Select>
        <TooltipMenu name={item.name} itemType={itemType} />
      </ToolTipController>
    ));
  }
}

const TooltipMenu = ({ name, itemType }) => {
  switch (itemType) {
    case 'npc':
      return (
        <ToolTip>
          <span onClick={() => send(`greet ${name}`)}>greet {name}</span>
          <br />
          <span onClick={() => send(`look ${name}`)}>look {name}</span>
        </ToolTip>
      );
    case 'player':
      return (
        <ToolTip>
          <span onClick={() => send(`look ${name}`)}>look {name}</span>
          <br />
          <span onClick={() => send(`greet ${name}`)}>greet {name}</span>
        </ToolTip>
      );
    case 'item':
      return (
        <ToolTip>
          <span onClick={() => send(`look ${name}`)}>look {name}</span>
          <br />
          <span onClick={() => send(`get ${name}`)}>get {name}</span>
        </ToolTip>
      );
    case 'shop':
      return (
        <ToolTip>
          <span onClick={() => send(`look ${name}`)}>look {name}</span>
          <br />
          <span onClick={() => send(`shop list`)}>shop list</span>
        </ToolTip>
      );
    default:
      return null;
  }
};

export default InteractableItem;
