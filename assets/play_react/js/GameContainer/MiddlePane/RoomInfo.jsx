import React from 'react';
import styled, { css } from 'styled-components';
import { connect } from 'react-redux';
import VmlToJsx from '../../SharedComponents/VmlToJsx.jsx';
import { theme } from '../../theme.js';
import { send } from '../../redux/actions/actions.js';

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
`;

const RoomInfo = ({ dispatch, className, roomInfo }) => {
  const { name, description, players, npcs, shops, items, exits } = roomInfo;
  return (
    <RoomInfoContainer>
      <RoomName>{name}</RoomName>
      <br />
      <br />
      <VmlToJsx vmlString={description} />
      <br />
      <div>
        {players.map(player => (
          <VmlToJsx vmlString={player.status_line} />
        ))}
        {'  '}
        {npcs.map(npc => (
          <VmlToJsx vmlString={npc.status_line} />
        ))}{' '}
        {'  '}
        {shops.map(shop => (
          <VmlToJsx vmlString={shop.name} />
        ))}
        {'  '}
        {/* Items in the Room.Info GMCP module are not VML tagged so we need to manually color them here. */}
        {items.map((item, idx, itemsArr) => (
          <ColoredSpan color={theme.vml.item} key={item.id}>
            {item.name}
            {idx === itemsArr.length - 1 ? (
              <ColoredSpan color={theme.text}>. </ColoredSpan>
            ) : (
              <ColoredSpan color={theme.text}>, </ColoredSpan>
            )}
          </ColoredSpan>
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
};

const mapStateToProps = ({ roomInfo }) => {
  return { roomInfo };
};

export default connect(mapStateToProps)(RoomInfo);
