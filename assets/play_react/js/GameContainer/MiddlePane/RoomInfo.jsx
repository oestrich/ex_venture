import React from 'react';
import styled, { css } from 'styled-components';
import { connect } from 'react-redux';
import VmlParser from '../../SharedComponents/VmlParser.jsx';
import { theme } from '../../theme.js';
import { send } from '../../redux/actions/actions.js';
import InteractableItem from './InteractableItem.jsx';

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

const ColoredSpan = styled.span`
  color: ${props => props.color};
  display: inline-block;
`;

const Exit = styled.span`
  color: ${theme.vml.exit};
  text-decoration: underline;
  cursor: pointer;
  padding-left: 0.5ch;
`;

class RoomInfo extends React.Component {
  constructor(props) {
    super(props);
    this.state = { selected: '' };
  }
  render() {
    const { dispatch } = this.props;
    const {
      name,
      description,
      players,
      npcs,
      shops,
      items,
      exits
    } = this.props.roomInfo;

    return (
      <RoomInfoContainer>
        <RoomName>{name}</RoomName>
        <br />
        <br />
        <VmlParser vmlString={description} />
        <br />
        <div>
          <InteractableItem items={players} itemType={'player'} />
          <InteractableItem items={npcs} itemType={'npc'} />
          <InteractableItem items={shops} itemType={'shop'} />
          <br />
          <br />
          {items.length > 0 ? 'Items: ' : null}
          <InteractableItem items={items} itemType={'item'} />
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

const mapStateToProps = ({ roomInfo }) => {
  return { roomInfo };
};

export default connect(mapStateToProps)(RoomInfo);
