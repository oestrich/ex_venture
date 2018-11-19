import React from 'react';
import styled, { css } from 'styled-components';
import { connect } from 'react-redux';

const RoomInfo = ({ className, roomInfo }) => {
  console.log('roomInfo', roomInfo);
  const { name, description, players, npcs, shops, items, exits } = roomInfo;
  return (
    <div className={className}>
      <div>{name}</div>
      <br />
      <div>{description}</div>
      <br />
      <div>
        {players
          ? players.map(player => <span key={player.id}>{player.name} </span>)
          : null}
        {npcs ? npcs.map(npc => <span key={npc.id}>{npc.name} </span>) : null}
        {shops
          ? shops.map(shop => <span key={shop.id}>{shop.name} </span>)
          : null}
        {items
          ? items.map(item => <span key={item.id}>{item.name} </span>)
          : null}
      </div>
      <br />
      <div>
        {exits
          ? exits.map(exit => <span key={exit.room_id}>{exit.direction} </span>)
          : null}
      </div>
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

export default connect(mapStateToProps)(styled(RoomInfo)``);
