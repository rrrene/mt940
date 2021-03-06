defmodule MT940.TagHandler do
  @moduledoc false

  import Helper
  use Timex


  def split(":25:", v, _) do
    case v |> String.contains?("/") do
      true  -> ~r/^(\d{8}|\w{8,11})\/(\d{1,23})(\D{3})?$/
      false -> ~r/^(.+)(\D{3})?$/
    end
    |> Regex.run(v, capture: :all_but_first)
    |> List.to_tuple
  end


  def split(":28:", v, line_separator) do
    v |> statement_number(line_separator)
  end


  def split(":28C:", v, line_separator) do
    v |> statement_number(line_separator)
  end


  def split(":60" <> <<_>> <> ":", v, line_separator) do
    v |> balance(line_separator)
  end


  def split(":61:", v, _) do
    l = ~r/^(\d{6})(\d{4}|)(C|RC|D|RD)(\D?)([0-9,]{2,15})(\w{4})(NONREF|.{1,22})(\/\/)?(\w{0,16})?([\s\R]{1,2})?(.{0,34})?$/
    |> Regex.run(v, capture: :all_but_first)
    |> List.update_at(4, &convert_to_decimal(&1))
    |> List.update_at(0, &DateFormat.parse!(&1, "{YY}{M}{D}"))

    value_date   = l |> Enum.at(0)
    booking_date = l |> Enum.at(1)

    case booking_date do
      "" -> l
      _  -> l |> List.update_at(1, &DateFormat.parse!("#{value_date.year}#{&1}", "{YYYY}{M}{D}"))
    end
    |> List.to_tuple
  end


  def split(":86:", v, line_separator) do
    s = ~r/^(\d{3})(\D)/
    |> Regex.run(v, capture: :all_but_first)

    case s do
      [code, separator] -> 
        fields = v
        |> remove_newline!(line_separator)
        |> String.split(Regex.compile!("(^\\d{3})?(\\#{separator})\\d{2}()"), on: :all_but_first, trim: true)
        |> Stream.chunk(2)
        |> Stream.map(fn [k, v] -> {String.to_integer(k), v |> String.replace(~r/\s{2,}/, " ") |> String.strip} end)
        |> Enum.into(HashDict.new)
        {code, fields}
      _ ->
        Regex.split(Regex.compile!(line_separator), v)
        |> Enum.join(" ")
        |> String.replace(~r/\s{2,}/, " ")
    end
  end


  def split(":62" <> <<_>> <> ":", v, line_separator) do
    v |> balance(line_separator)
  end


  def split(":90" <> <<_>> <> ":", v, _) do
    ~r/^(\d{1,5})(\w{3})([0-9,]{1,15})$/
    |> Regex.run(v, capture: :all_but_first)
    |> List.update_at(0, &String.to_integer/1)
    |> List.update_at(2, &convert_to_decimal/1)
    |> List.to_tuple
  end


  def split(_, v, _) when is_binary(v) do
    v
  end


  def balance(v, line_separator) do
    ~r/^(\w{1})(\d{6})(\w{3})([0-9,]{1,15}).*$/
    |> Regex.run(v |> remove_newline!(line_separator), capture: :all_but_first)
    |> List.update_at(1, &DateFormat.parse!(&1, "{YY}{M}{D}"))
    |> List.update_at(3, &convert_to_decimal(&1))
    |> List.to_tuple
  end


  def statement_number(v, line_separator) do
    ~r/^(\d+)\/?(\d+)?$/
    |> Regex.run(v |> remove_newline!(line_separator), capture: :all_but_first)
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end
end
