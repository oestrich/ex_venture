import React from 'react';
import styled, { css } from 'styled-components';
import { connect } from 'react-redux';
import VmlParser from '../../SharedComponents/VmlParser.jsx';
import { theme } from '../../theme.js';
import { send } from '../../redux/actions/actions.js';
import { ToolTipController, Select } from 'react-tooltip-controller';

const RoomInfoContainer = styled.div`
  padding: 2em 2em 1em 2em;
`;

const Centered = styled.div`
  display: flex;
  justify-content: center;
`;

const RoomName = styled.div`
  display: flex;
  justify-content: center;
  font-size: 20px;
  font-weight: bold;
`;

const Exit = styled.span`
  color: ${theme.vml.exit};
  text-decoration: underline;
  cursor: pointer;
  padding-left: 0.5ch;
`;

const ColoredSpan = styled.span`
  color: ${props => props.color};
  display: inline-block;
`;

const InteractableItem = styled.div`
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

class RoomInfo extends React.Component {
  constructor(props) {
    super(props);
    this.state = { selected: '' };
  }
  render() {
    const {
      name,
      description,
      players,
      npcs,
      shops,
      items,
      exits
    } = this.props.roomInfo;
    const { dispatch } = this.props;
    return (
      <RoomInfoContainer>
        <RoomName>{name}</RoomName>
        <br />
        <br />
        <VmlParser vmlString={description} />
        <br />
        <div>
          {players.map(player => (
            <ToolTipController
              key={idx}
              id={`npc-tooltip-${idx}`}
              returnState={isTooltipShowing => {
                if (isTooltipShowing) {
                  this.setState({ selected: `player-tooltip-${idx}` }, () =>
                    send(`target ${player.name}`)
                  );
                } else if (this.state.selected === `player-tooltip-${idx}`) {
                  this.setState({ selected: '' });
                }
              }}
              detect="click"
              offsetX={200}
              offsetY={2}
            >
              <Select>
                <InteractableItem
                  selected={
                    this.state.selected === `player-tooltip-${idx}`
                      ? true
                      : false
                  }
                >
                  <VmlParser vmlString={player.status_line} />
                </InteractableItem>
              </Select>
              <PlayerTooltipMenu name={player.name} />
            </ToolTipController>
          ))}
          {npcs.map((npc, idx) => (
            <ToolTipController
              key={idx}
              id={`npc-tooltip-${idx}`}
              returnState={isTooltipShowing => {
                if (isTooltipShowing) {
                  this.setState({ selected: `npc-tooltip-${idx}` }, () =>
                    send(`target ${npc.name}`)
                  );
                } else if (this.state.selected === `npc-tooltip-${idx}`) {
                  this.setState({ selected: '' });
                }
              }}
              detect="click"
              offsetX={200}
              offsetY={2}
            >
              <Select>
                <InteractableItem
                  selected={
                    this.state.selected === `npc-tooltip-${idx}` ? true : false
                  }
                >
                  <VmlParser vmlString={npc.status_line} />
                </InteractableItem>
              </Select>
              <NpcTooltipMenu name={npc.name} />
            </ToolTipController>
          ))}
          {shops.map((shop, idx) => (
            <ToolTipController
              key={idx}
              id={`shop-tooltip-${idx}`}
              returnState={isTooltipShowing => {
                if (isTooltipShowing) {
                  this.setState({ selected: `shop-tooltip-${idx}` }, () =>
                    send(`target ${shop.name}`)
                  );
                } else if (this.state.selected === `shop-tooltip-${idx}`) {
                  this.setState({ selected: '' });
                }
              }}
              detect="click"
              offsetX={200}
              offsetY={2}
            >
              <Select>
                <InteractableItem
                  selected={
                    this.state.selected === `shop-tooltip-${idx}` ? true : false
                  }
                >
                  <VmlParser vmlString={shop.name} />
                </InteractableItem>
              </Select>
              <ShopTooltipMenu name={shop.name} />
            </ToolTipController>
          ))}
          {/* Items in the Room.Info GMCP module are not VML tagged so we need to manually color them here. */}
          <br />
          <br />
          {items.length > 0 ? 'Items: ' : null}
          {items.map((item, idx, itemsArr) => (
            <ToolTipController
              key={idx}
              id={`item-tooltip-${idx}`}
              returnState={isTooltipShowing => {
                if (isTooltipShowing) {
                  this.setState({ selected: `item-tooltip-${idx}` }, () =>
                    send(`target ${item.name}`)
                  );
                } else if (this.state.selected === `item-tooltip-${idx}`) {
                  this.setState({ selected: '' });
                }
              }}
              detect="click"
              offsetX={200}
              offsetY={2}
            >
              <Select>
                <InteractableItem
                  selected={
                    this.state.selected === `item-tooltip-${idx}` ? true : false
                  }
                >
                  <ColoredSpan color={theme.vml.item} key={item.id}>
                    {item.name}
                    {idx === itemsArr.length - 1 ? (
                      <ColoredSpan color={theme.text}>. </ColoredSpan>
                    ) : (
                      <ColoredSpan color={theme.text}>, </ColoredSpan>
                    )}
                  </ColoredSpan>
                </InteractableItem>
              </Select>
              <ItemTooltipMenu name={item.name} />
            </ToolTipController>
          ))}{' '}
        </div>
        <br />
        <Centered>
          {exits.length > 0 ? 'You can leave ' : null}
          {exits.map((exit, idx, exitsArr) => (
            <Exit
              onClick={() => {
                dispatch(send(exit.direction));
              }}
              key={exit.room_id}
            >
              {' '}
              {exit.direction}
              {idx === exitsArr.length - 1 ? (
                <ColoredSpan color={theme.text}>. </ColoredSpan>
              ) : (
                <ColoredSpan color={theme.text}>, </ColoredSpan>
              )}
            </Exit>
          ))}
        </Centered>
        <br />
      </RoomInfoContainer>
    );
  }
}

const NpcTooltipMenu = ({ name }) => {
  return (
    <ToolTip>
      <span onClick={() => send(`greet ${name}`)}>greet {name}</span>
      <br />
      <span onClick={() => send(`look ${name}`)}>look {name}</span>
    </ToolTip>
  );
};

const PlayerTooltipMenu = ({ name }) => {
  return (
    <ToolTip>
      <span onClick={() => send(`look ${name}`)}>look {name}</span>
      <br />
      <span onClick={() => send(`greet ${name}`)}>greet {name}</span>
    </ToolTip>
  );
};

const ItemTooltipMenu = ({ name }) => {
  return (
    <ToolTip>
      <span onClick={() => send(`look ${name}`)}>look {name}</span>
      <br />
      <span onClick={() => send(`get ${name}`)}>get {name}</span>
    </ToolTip>
  );
};

const ShopTooltipMenu = ({ name }) => {
  return (
    <ToolTip>
      <span onClick={() => send(`look ${name}`)}>look {name}</span>
      <br />
      <span onClick={() => send(`shop list`)}>shop list</span>
    </ToolTip>
  );
};

const mapStateToProps = ({ roomInfo }) => {
  return { roomInfo };
};

export default connect(mapStateToProps)(RoomInfo);
