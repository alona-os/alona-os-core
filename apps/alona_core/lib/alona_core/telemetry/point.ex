defmodule AlonaCore.Telemetry.Point do
  @moduledoc """
  canonical normalized telemetry reading before persistence.
  """

  @type t :: %__MODULE__{
          property_slug: String.t() | nil,
          stream_slug: String.t() | nil,
          stream_id: pos_integer() | nil,
          measured_at: DateTime.t() | nil,
          value_number: number() | nil,
          value_text: String.t() | nil,
          value_boolean: boolean() | nil,
          quality: integer() | nil,
          raw_payload: map() | nil,
          source: map() | nil,
          external_id: String.t() | nil
        }

  @enforce_keys []
  defstruct [
    :property_slug,
    :stream_slug,
    :stream_id,
    :measured_at,
    :value_number,
    :value_text,
    :value_boolean,
    :quality,
    :raw_payload,
    :source,
    :external_id
  ]

  @value_fields [:value_number, :value_text, :value_boolean]

  @doc """
  validates and normalizes a point struct or keyword/map attrs.
  """
  def new(attrs) when is_map(attrs) do
    point = struct(__MODULE__, Map.take(attrs, Map.keys(%__MODULE__{})))

    with :ok <- validate_stream_identification(point),
         :ok <- validate_single_value(point),
         {:ok, measured_at} <- normalize_measured_at(point.measured_at) do
      {:ok, %{point | measured_at: measured_at, raw_payload: normalize_raw_payload(point)}}
    end
  end

  @doc """
  maps a validated point and resolved stream id into attrs for measurement persistence.
  """
  def to_measurement_attrs(%__MODULE__{} = point, stream_id) when is_integer(stream_id) do
    %{
      stream_id: stream_id,
      measured_at: point.measured_at,
      value_number: point.value_number,
      value_text: point.value_text,
      value_boolean: point.value_boolean,
      quality: point.quality,
      raw_payload: build_raw_payload(point)
    }
  end

  defp validate_stream_identification(%__MODULE__{stream_id: id, stream_slug: slug}) do
    cond do
      is_integer(id) -> :ok
      is_binary(slug) and slug != "" -> :ok
      true -> {:error, :invalid_point}
    end
  end

  defp validate_single_value(%__MODULE__{} = point) do
    present =
      @value_fields
      |> Enum.filter(fn field ->
        value = Map.get(point, field)
        not is_nil(value)
      end)

    case present do
      [_] -> :ok
      [] -> {:error, :invalid_point}
      _ -> {:error, :invalid_point}
    end
  end

  defp normalize_measured_at(nil), do: {:ok, DateTime.utc_now(:microsecond)}

  defp normalize_measured_at(%DateTime{} = dt), do: {:ok, dt}

  defp normalize_measured_at(_), do: {:error, :invalid_point}

  defp normalize_raw_payload(%__MODULE__{raw_payload: payload}) when is_map(payload), do: payload
  defp normalize_raw_payload(%__MODULE__{}), do: %{}

  defp build_raw_payload(%__MODULE__{} = point) do
    point
    |> normalize_raw_payload()
    |> maybe_put_meta(:source, point.source)
    |> maybe_put_meta(:external_id, point.external_id)
  end

  defp maybe_put_meta(payload, _key, nil), do: payload
  defp maybe_put_meta(payload, key, value), do: Map.put(payload, key, value)
end
