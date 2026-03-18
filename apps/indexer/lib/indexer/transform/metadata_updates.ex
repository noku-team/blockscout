defmodule Indexer.Transform.MetadataUpdates do
  @moduledoc """
  Parses logs for token metadata update events and returns a list of token instances
  whose metadata should be invalidated and re-fetched.

  Handles:
    - EIP-4906 `MetadataUpdate(uint256 _tokenId)`
    - EIP-4906 `BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId)`
    - Custom `MetadataChanged(uint256 indexed tokenId, string metadataURI)`
  """

  require Logger

  import Explorer.Helper, only: [decode_data: 2]

  alias Explorer.Chain.Token.Instance
  alias Explorer.Repo

  import Ecto.Query, only: [from: 2]

  @metadata_update "0xf8e1a15aba9398e019f0b49df1a4fde98ee17ae345cb5f6b5e2c27f5033e8ce7"
  @batch_metadata_update "0x6bd5c950a8d8df17f772f5af37cb3655737899cbf903264b9795592da439661c"
  @metadata_changed "0x2822080855c1a796047f86db6703ee05ff65e9ab90092ca4114af8f017f2047e"

  @doc """
  Parses logs to extract token instances whose metadata has been updated.

  Returns `%{metadata_updates: [%{contract_address_hash: hash, token_id: id}, ...]}`.
  """
  @spec parse(list()) :: %{metadata_updates: list()}
  def parse(logs) do
    metadata_updates =
      logs
      |> Enum.flat_map(&parse_event/1)
      |> Enum.uniq()

    %{metadata_updates: metadata_updates}
  end

  defp parse_event(%{first_topic: @metadata_update, data: data, address_hash: address_hash})
       when not is_nil(data) do
    case decode_data(data, [{:uint, 256}]) do
      [token_id] when not is_nil(token_id) ->
        [%{contract_address_hash: address_hash, token_id: token_id}]

      _ ->
        []
    end
  rescue
    _ -> []
  end

  defp parse_event(%{first_topic: @batch_metadata_update, data: data, address_hash: address_hash})
       when not is_nil(data) do
    case decode_data(data, [{:uint, 256}, {:uint, 256}]) do
      [from_token_id, to_token_id] when not is_nil(from_token_id) and not is_nil(to_token_id) ->
        fetch_instance_ids_in_range(address_hash, from_token_id, to_token_id)

      _ ->
        []
    end
  rescue
    _ -> []
  end

  defp parse_event(%{first_topic: @metadata_changed, second_topic: second_topic, address_hash: address_hash})
       when not is_nil(second_topic) do
    case decode_data(second_topic, [{:uint, 256}]) do
      [token_id] when not is_nil(token_id) ->
        [%{contract_address_hash: address_hash, token_id: token_id}]

      _ ->
        []
    end
  rescue
    _ -> []
  end

  defp parse_event(_), do: []

  defp fetch_instance_ids_in_range(address_hash, from_token_id, to_token_id) do
    from(ti in Instance,
      where:
        ti.token_contract_address_hash == ^address_hash and
          ti.token_id >= ^from_token_id and
          ti.token_id <= ^to_token_id,
      select: %{contract_address_hash: ti.token_contract_address_hash, token_id: ti.token_id}
    )
    |> Repo.all()
  rescue
    _ -> []
  end
end
