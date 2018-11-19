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
      {players ? players.map(player => <span>{player.name} </span>) : null}
      {npcs ? npcs.map(npc => <span>{npc.name} </span>) : null}
      {shops ? shops.map(shop => <span>{shop.name} </span>) : null}
      {items ? items.map(item => <span>{item.name} </span>) : null}
      <br />
      {exits ? exits.map(exit => <span>{exit.direction} </span>) : null}
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
