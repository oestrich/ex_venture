defmodule Representer do
  defmodule Collection do
    defstruct [:name, :items, :links]
  end

  defmodule Item do
    defstruct [:item, :links]
  end

  defmodule Link do
    defstruct [:rel, :href, :title, :template]
  end

  def transform(struct, extension) do
    case extension do
      "hal" ->
        Representer.HAL.transform(struct)

      "siren" ->
        Representer.Siren.transform(struct)
    end
  end

  defmodule Adapter do
    @type json :: map()

    @callback transform(collection :: %Representer.Collection{}) :: json()

    @callback transform(item :: %Representer.Item{}) :: json()
  end

  defmodule HAL do
    @behaviour Representer.Adapter

    def transform(collection = %Representer.Collection{}) do
      %{
        "_embedded" => %{
          collection.name => Enum.map(collection.items, &transform/1),
        },
        "_links" => transform_links(collection.links)
      }
    end

    def transform(item = %Representer.Item{}) do
      Map.put(item.item, "_links", transform_links(item.links))
    end

    defp maybe_put(map, _key, nil), do: map

    defp maybe_put(map, key, value) do
      Map.put(map, key, value)
    end

    def transform_links(links) do
      Enum.reduce(links, %{}, fn link, links ->
        json =
          %{"href" => link.href}
          |> maybe_put(:name, link.title)
          |> maybe_put(:template, link.template)

        case Map.get(links, link.rel) do
          nil ->
            Map.put(links, link.rel, json)

          existing_links ->
            Map.put(links, link.rel, [json | List.wrap(existing_links)])
        end
      end)
    end
  end

  defmodule Siren do
    @behaviour Representer.Adapter

    def transform(collection = %Representer.Collection{}) do
      %{
        "entities" => Enum.map(collection.items, &transform/1),
        "links" => transform_links(collection.links)
      }
    end

    def transform(item = %Representer.Item{}) do
      %{
        "properties" => item.item,
        "links" => transform_links(item.links),
      }
    end

    def transform_links(links) do
      Enum.map(links, fn link ->
        %{"rel" => [link.rel], "href" => link.href}
      end)
    end
  end
end
