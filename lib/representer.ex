defmodule Representer do
  defmodule Collection do
    defstruct [:name, :items, :links, :pagination]
  end

  defmodule Item do
    defstruct [:item, :links]
  end

  defmodule Link do
    defstruct [:rel, :href, :title, :template]
  end

  defmodule Pagination do
    defstruct [:base_url, :current_page, :total_pages, :total_count]

    @doc """
    Maybe add pagination links to the link list

    If pagination is nil, skip this
    """
    def maybe_paginate(links, nil), do: links

    def maybe_paginate(links, pagination) do
      cond do
        pagination.total_pages == 1 ->
          links

        pagination.current_page == 1 ->
          [next_link(pagination) | links]

        pagination.current_page == pagination.total_pages ->
          [prev_link(pagination) | links]

        true ->
          [next_link(pagination) | [prev_link(pagination) | links]]
      end
    end

    defp next_link(pagination) do
      %Representer.Link{rel: "next", href: page_path(pagination.base_url, pagination.current_page + 1)}
    end

    defp prev_link(pagination) do
      %Representer.Link{rel: "prev", href: page_path(pagination.base_url, pagination.current_page - 1)}
    end

    defp page_path(path, page) do
      uri = URI.parse(path)

      query =
        uri.query
        |> decode_query()
        |> Map.put(:page, page)
        |> URI.encode_query()

      %{uri | query: query}
      |> URI.to_string()
    end

    defp decode_query(nil), do: %{}

    defp decode_query(query) do
      URI.decode_query(query)
    end
  end

  @doc """
  Transform the internal representation based on the extension
  """
  def transform(struct, extension) do
    case extension do
      "hal" ->
        Representer.HAL.transform(struct)

      "siren" ->
        Representer.Siren.transform(struct)
    end
  end

  defmodule Adapter do
    @moduledoc """
    Behaviour for representations to implement
    """

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
        "_links" => collection.links |> Representer.Pagination.maybe_paginate(collection.pagination) |> transform_links()
      }
    end

    def transform(item = %Representer.Item{}) do
      Map.put(item.item, "_links", transform_links(item.links))
    end

    defp maybe_put(map, _key, nil), do: map

    defp maybe_put(map, key, value) do
      Map.put(map, key, value)
    end

    defp transform_links(links) do
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
      links =
        collection.links
        |> Representer.Pagination.maybe_paginate(collection.pagination)
        |> transform_links()

      %{
        "entities" => Enum.map(collection.items, &transform/1),
        "links" => links
      }
    end

    def transform(item = %Representer.Item{}) do
      %{
        "properties" => item.item,
        "links" => transform_links(item.links),
      }
    end

    defp transform_links(links) do
      Enum.map(links, fn link ->
        %{"rel" => [link.rel], "href" => link.href}
      end)
    end
  end
end
