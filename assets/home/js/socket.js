import { Socket } from 'phoenix';
import Sizzle from 'sizzle';
import _ from 'underscore';

import { format } from './color.js';

var body = document.getElementById('body');
var characterToken = body.getAttribute('data-character-token');

class Channels {
  join() {
    this.socket = new Socket('/socket', { params: { token: characterToken } });
    this.socket.connect();

    this.channels = {};

    _.each(Sizzle('.channel'), channel => {
      this.connectChannel(channel);
    });

    this.connectSend();
    this.connectTabHandlers();
  }

  connectChannel(channelEl) {
    let channelName = channelEl.dataset.channel;

    let channel = this.socket.channel(`chat:${channelName}`, {});
    this.channels[channelName] = channel;

    channel.on('broadcast', data => {
      this.alertChannel(channelName);
      this.appendMessage(channelEl, data);
    });

    channel.join().receive('ok', data => {
      this.appendMessage(channelEl, { message: 'Connected' });
      _.each(data, message => {
        this.appendMessage(channelEl, message);
      });
    });
  }

  connectSend() {
    let chatPrompt = _.first(Sizzle('#chat-prompt'));
    chatPrompt.addEventListener('keypress', e => {
      if (e.keyCode == 13) {
        this.sendMessage();
      }
    });

    let send = _.first(Sizzle('#chat-send'));
    send.addEventListener('click', e => {
      this.sendMessage();
    });
  }

  connectTabHandlers() {
    _.each(Sizzle('.channel-tab'), channelTab => {
      channelTab.addEventListener('click', e => {
        let bellIcon = _.first(Sizzle('.bell', channelTab));
        bellIcon.classList.add('hidden');
      });
    });
  }

  sendMessage() {
    let chatPrompt = _.first(Sizzle('#chat-prompt'));
    let activeChannel = _.first(Sizzle('.channel.active'));
    let channel = this.channels[activeChannel.dataset.channel];
    if (chatPrompt.value != '') {
      channel.push('send', { message: chatPrompt.value });
      chatPrompt.value = '';
    }
  }

  appendMessage(channelEl, data) {
    var fragment = document.createDocumentFragment();
    let html = document.createElement('div');
    html.innerHTML = format(data);
    fragment.appendChild(html);

    channelEl.appendChild(fragment);
  }

  alertChannel(channelName) {
    let channelTab = _.first(
      Sizzle(`.channel-tab[data-channel="${channelName}"]`)
    );
    let activeChannel = _.first(Sizzle('.channel.active'));
    if (activeChannel.dataset.channel != channelName) {
      let bellIcon = _.first(Sizzle('.bell', channelTab));
      bellIcon.classList.remove('hidden');
    }
  }
}

export { Channels };
