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
        {players
          ? players.map(player => (
              <span key={player.id}>{player.status_line} </span>
            ))
          : null}
        {npcs ? npcs.map(npc => vmlToJsx(npc.status_line)) : null}
        {shops
          ? shops.map(shop => <span key={shop.id}>{shop.name} </span>)
          : null}
        {items
          ? items.map(item => <span key={item.id}>{item.name} </span>)
          : null}
      </div>
      <br />
      <Centered>
        You can leave:{' '}
        {exits
          ? exits.map(exit => <span key={exit.room_id}>{exit.direction}</span>)
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
  padding: 1em 1em 1em 1em;
`);
