ExUnit.start()

defmodule MT940.Account do
  use MT940


  def balance(raw) when is_binary(raw) do
    {_, _, currency, amount} = parse!(raw) |> Enum.at(-1) |> Dict.get(:":62F:")
    "#{amount} #{currency}"
  end


  def transactions(raw) when is_binary(raw) do
    parse!(raw)
    |> Stream.flat_map(&Keyword.take(&1, [:":61:", :":86:"]))
    |> Stream.map(fn {_, v} -> v end)
    |> Stream.chunk(2)
    |> Enum.map(fn [{_, booking_date, _, _, amount, _, _, _, _, _, _}, {_, info}] ->

      %{
        booking_date: booking_date,
        amount:       amount,
        purpose:      info
          |> Dict.take([20..29, 60..63] |> Enum.concat)
          |> Dict.values
          |> Enum.join
      }
    end)
  end

end
