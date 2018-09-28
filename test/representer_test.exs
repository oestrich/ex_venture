defmodule RepresenterTest do
  use ExUnit.Case

  alias Representer.CollectionJSON
  alias Representer.HAL
  alias Representer.Item
  alias Representer.JSON
  alias Representer.Link
  alias Representer.Mason
  alias Representer.Siren

  describe "collection+json representation" do
    setup do
      self_link = %Link{rel: "self", href: "/"}

      %{data: %{key: :value}, links: [self_link]}
    end

    test "an item", %{data: data, links: links} do
      item = %Item{
        href: "/item",
        item: data,
        links: links,
      }

      assert CollectionJSON.transform(item) == %{
        "collection" => %{
          "version" => "1.0",
          "items" => [
            %{
              "href" => "/item",
              "data" => [
                %{"name" => :key, "value" => :value}
              ],
            }
          ]
        }
      }
    end
  end

  describe "hal representation" do
    setup do
      self_link = %Link{rel: "self", href: "/"}

      %{data: %{key: :value}, links: [self_link]}
    end

    test "an item", %{data: data, links: links} do
      item = %Item{item: data, links: links}

      assert HAL.transform(item) == %{
        "_links" => %{
          "self" => %{"href" => "/"}
        },
        key: :value
      }
    end
  end

  describe "json representation" do
    setup do
      self_link = %Link{rel: "self", href: "/"}

      %{data: %{key: :value}, links: [self_link]}
    end

    test "an item", %{data: data, links: links} do
      item = %Item{item: data, links: links}

      assert JSON.transform(item) == %{
        "links" => [
          %{"rel" => "self", "href" => "/"}
        ],
        key: :value
      }
    end
  end

  describe "mason representation" do
    setup do
      self_link = %Link{rel: "self", href: "/"}

      %{data: %{key: :value}, links: [self_link]}
    end

    test "an item", %{data: data, links: links} do
      item = %Item{
        rel: "data",
        item: data,
        links: links,
      }

      assert Mason.transform(item) == %{
        :key => :value,
        "@controls" => %{
          "self" => %{"href" => "/"}
        }
      }
    end
  end

  describe "siren representation" do
    setup do
      self_link = %Link{rel: "self", href: "/"}

      %{data: %{key: :value}, links: [self_link]}
    end

    test "an item", %{data: data, links: links} do
      item = %Item{
        rel: "data",
        item: data,
        links: links,
      }

      assert Siren.transform(item) == %{
        "rel" => "data",
        "properties" => %{
          key: :value
        },
        "links" => [
          %{"rel" => ["self"], "href" => "/"}
        ]
      }
    end
  end
end
