import React from 'react';
import styled, { css } from 'styled-components';
import { connect } from 'react-redux';
import vmlToJsx from '../../utils/vmlToJsx.js';

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
  color: white;
  cursor: pointer;
`;

const RoomInfo = ({ className, roomInfo }) => {
  console.log('roomInfo', roomInfo);
  const { name, description, players, npcs, shops, items, exits } = roomInfo;
  return (
    <div className={className}>
      <br />
      <RoomName>{name}</RoomName>
      <br />
      <br />
      <div>{vmlToJsx(description)}</div>
      <br />
      <div>
        {players ? players.map(player => vmlToJsx(player.status_line)) : null}
        {'  '}
        {npcs ? npcs.map(npc => vmlToJsx(npc.status_line)) : null} {'  '}
        {shops ? shops.map(shop => vmlToJsx(shop.name)) : null}
        {'  '}
        {items
          ? items.map((item, idx, itemsArr) => (
              <span style={{ color: '#4DFFFF' }} key={item.id}>
                {item.name}
                {idx === itemsArr.length - 1 ? (
                  <span style={{ color: '#c4e9e9' }}>. </span>
                ) : (
                  <span style={{ color: '#c4e9e9' }}>, </span>
                )}
              </span>
            ))
          : null}
      </div>
      <br />
      <Centered>
        {exits ? 'You can leave: ' : null}
        {exits
          ? exits.map(exit => (
              <Exit
                onClick={() => {
                  send(exit.direction);
                }}
                style={{ color: 'white' }}
                key={exit.room_id}
              >
                {exit.direction}
                {}
              </Exit>
            ))
          : null}
      </Centered>
      <br />
    </div>
  );
};

RoomInfo.defaultProps = {
  roomInfo: {
    name: '',
    description: '',
    players: [],
    npcs: [],
    shops: [],
    items: [],
    exits: []
  }
};

const mapStateToProps = state => {
  return { roomInfo: state.roomInfo };
};

export default connect(mapStateToProps)(styled(RoomInfo)`
  padding: 1em 2em 1em 2em;
`);
