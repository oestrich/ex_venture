# Gossip Network

To connect to the Gossip network, sign up for an account on [Gossip](https://gossip.haus/).

## Configure Keys

Configure your Gossip keys in `config/prog.secret.exs` or `config/dev.local.exs` depending on
the environment. You can get the Client ID and Client secret after signing in or registering
from [Gossip Config](https://gossip.haus/config).

```elixir
config :gossip, :client_id, "get from gossip.haus/config"
config :gossip, :client_secret, "get from gossip.haus/config"
```

## Connecting Channels to Gossip

Once you configured Gossip, you can attach local channels to the network from the Channels admin panel.

![Channels Attach Gossip](/images/channels-attach-gossip.png)

Create a new channel and check is connected to the Gossip Network. Set the gossip remote channel name to
a channel you are subscribed to. After this, remote messages will start filtering into the local chat and
local chat will be pushed up to the network.

*Note:* Gossip channels are not logged locally.
