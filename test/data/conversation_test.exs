defmodule Data.ConversationTest do
  use Data.ModelCase
  doctest Data.Conversation

  alias Data.Conversation

  describe "validate conversations" do
    test "must include a start key" do
      conversations = [%Conversation{key: "start", message: "Hi"}]
      assert Conversation.valid_conversations?(conversations)

      conversations = [%Conversation{key: "end", message: "Hi"}]
      refute Conversation.valid_conversations?(conversations)
    end

    test "each key must be present" do
      conversations = [
        %Conversation{key: "start", message: "Hi", listen: [%{phrase: "yes", key: "continue"}]},
        %Conversation{key: "continue", message: "Hi"},
      ]
      assert Conversation.valid_conversations?(conversations)

      conversations = [
        %Conversation{key: "start", message: "Hi", listen: [%{phrase: "yes", key: "continue"}]},
      ]
      refute Conversation.valid_conversations?(conversations)
    end
  end
end
