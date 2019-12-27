defmodule Gelato.Logger.Item do
  @moduledoc false

  defstruct [:timestamp, :level, :message, :type, metadata: [], context: %{}]

  @type t :: %__MODULE__{
          timestamp: binary(),
          level: Logger.level(),
          message: Logger.message(),
          type: atom(),
          metadata: Logger.metadata(),
          context: map()
        }

  @doc """
  Creates a new `Item` struct
  """
  @spec create(
          level :: Logger.level(),
          timestamp :: nil | DateTime.t(),
          message :: Logger.message(),
          metadata :: keyword()
        ) :: t()
  def create(level, timestamp \\ nil, message, metadata \\ []) do
    case Jason.decode(message, keys: :atoms) do
      {:ok, message} ->
        {context, message} = Map.pop(message, :context)
        {explicit_metadata, message} = Map.pop(message, :metadata)
        {type, message} = Map.pop(message, :type, :default)

        metadata = Keyword.merge(metadata, Map.to_list(explicit_metadata))

        %__MODULE__{
          timestamp: fix_timestamp(timestamp),
          level: level,
          type: type,
          message: message,
          metadata: Keyword.update(metadata, :pid, inspect(self()), &inspect/1),
          context: context
        }

      {:error, reason} ->
        %__MODULE__{
          timestamp: fix_timestamp(nil),
          level: :error,
          type: "unknown",
          message: inspect(reason),
          metadata: Keyword.update(metadata, :pid, inspect(self()), &inspect/1),
          context: []
        }
    end
  end

  @spec fix_timestamp(timestamp :: nil | :calendar.datetime()) :: binary()
  @doc false
  defp fix_timestamp(nil),
    do: DateTime.utc_now() |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()

  defp fix_timestamp({{_, _, _} = d, {h, m, s, ms}}) do
    with {:ok, timestamp} <- NaiveDateTime.from_erl({d, {h, m, s}}, {ms * 1_000, 3}),
         result <- NaiveDateTime.to_iso8601(timestamp) do
      "#{result}Z"
    end
  end
end