export default class ChannelWrapper {
  constructor(channel) {
    this.channel = channel;
  }

  join() {
    this.channel.join();
  }

  send(message) {
    this.channel.push("recv", {message: message});
  }

  sendGMCP(module, data) {
    this.channel.push("gmcp", {module, data});
  }
}
