defmodule Exop.ValidationChecks do
  @moduledoc """
  Provides low-level validation functions:

    * check_type/3
    * check_required/3
    * check_numericality/3
    * check_in/3
    * check_not_in/3
    * check_format/3
    * check_length/3
    * check_struct/3
    * check_func/3
    * check_equals/3
    * check_exactly/3
    * check_allow_nil/3
  """

  alias Exop.TypeValidation

  @no_check_item :exop_no_check_item

  @type check_error :: %{(atom() | String.t()) => String.t()}

  @doc """
  Returns an check_item's value from either a Keyword or a Map by an atom-key.

  ## Examples

      iex> Exop.ValidationChecks.get_check_item(%{a: 1, b: 2}, :a)
      1

      iex> Exop.ValidationChecks.get_check_item([a: 1, b: 2], :b)
      2

      iex> Exop.ValidationChecks.get_check_item(%{a: 1, b: 2}, :c)
      nil
  """
  @spec get_check_item(map(), atom() | String.t()) :: any() | nil
  def get_check_item(check_items, item_name) when is_map(check_items) do
    Map.get(check_items, item_name)
  end

  def get_check_item(check_items, item_name) when is_list(check_items) do
    Keyword.get(check_items, item_name)
  end

  def get_check_item(_check_items, _item), do: nil

  @doc """
  Checks whether a check_item has been provided.
  Returns a boolean.

  ## Examples

      iex> Exop.ValidationChecks.check_item_present?(%{a: 1, b: 2}, :a)
      true

      iex> Exop.ValidationChecks.check_item_present?([a: 1, b: 2], :b)
      true

      iex> Exop.ValidationChecks.check_item_present?(%{a: 1, b: 2}, :c)
      false

      iex> Exop.ValidationChecks.check_item_present?(%{a: 1, b: nil}, :b)
      true
  """
  @spec check_item_present?(map(), atom() | String.t()) :: boolean()
  def check_item_present?(check_items, item_name) when is_map(check_items) do
    Map.get(check_items, item_name, @no_check_item) != @no_check_item
  end

  def check_item_present?(check_items, item_name) when is_list(check_items) do
    Keyword.get(check_items, item_name, @no_check_item) != @no_check_item
  end

  def check_item_present?(_check_items, _item), do: false

  @doc """
  Checks if an item_name presents in params if its required (true).

  ## Examples

      iex> Exop.ValidationChecks.check_required(%{}, :some_item, false)
      true

      iex> Exop.ValidationChecks.check_required([a: 1, b: 2], :a, true)
      true

      iex> Exop.ValidationChecks.check_required(%{a: 1, b: 2}, :b, true)
      true
  """
  @spec check_required(map(), atom() | String.t(), boolean) :: true | check_error
  def check_required(_check_items, _item, false), do: true

  def check_required(check_items, item_name, true) do
    check_item_present?(check_items, item_name) || %{item_name => "is required"}
  end

  @doc """
  Checks the type of an item_name.

  ## Examples

      iex> Exop.ValidationChecks.check_type(%{a: 1}, :a, :integer)
      true

      iex> Exop.ValidationChecks.check_type(%{a: "1"}, :a, :string)
      true

      iex> Exop.ValidationChecks.check_type(%{a: nil}, :a, :string)
      %{:a => "has wrong type; expected type: string, got: nil"}
  """
  @spec check_type(map(), atom() | String.t(), atom()) :: true | check_error
  def check_type(check_items, item_name, check) do
    if check_item_present?(check_items, item_name) do
      check_item = get_check_item(check_items, item_name)

      TypeValidation.check_value(check_item, check) ||
        %{item_name => "has wrong type; expected type: #{check}, got: #{inspect(check_item)}"}
    else
      true
    end
  end

  @doc """
  Checks an item_name over numericality constraints.

  ## Examples

      iex> Exop.ValidationChecks.check_numericality(%{a: 3}, :a, %{ equal_to: 3 })
      true

      iex> Exop.ValidationChecks.check_numericality(%{a: 5}, :a, %{ greater_than_or_equal_to: 3 })
      true

      iex> Exop.ValidationChecks.check_numericality(%{a: 3}, :a, %{ less_than_or_equal_to: 3 })
      true
  """
  @spec check_numericality(map(), atom() | String.t(), map()) :: true | check_error
  def check_numericality(check_items, item_name, checks) do
    if check_item_present?(check_items, item_name) do
      check_item = get_check_item(check_items, item_name)

      cond do
        is_number(check_item) ->
          result = checks |> Enum.map(&check_number(check_item, item_name, &1))
          if Enum.all?(result, &(&1 == true)), do: true, else: result

        true ->
          %{item_name => "not a number. got: #{inspect(check_item)}"}
      end
    else
      true
    end
  end

  @spec check_number(number, atom() | String.t(), {atom, number}) :: boolean
  defp check_number(number, item_name, {:equal_to, check_value}) do
    if number == check_value do
      true
    else
      %{item_name => "must be equal to #{check_value}; got: #{inspect(number)}"}
    end
  end

  defp check_number(number, item_name, {:eq, check_value}) do
    check_number(number, item_name, {:equal_to, check_value})
  end

  defp check_number(number, item_name, {:equals, check_value}) do
    check_number(number, item_name, {:equal_to, check_value})
  end

  defp check_number(number, item_name, {:is, check_value}) do
    check_number(number, item_name, {:equal_to, check_value})
  end

  defp check_number(number, item_name, {:greater_than, check_value}) do
    if number > check_value do
      true
    else
      %{item_name => "must be greater than #{check_value}; got: #{inspect(number)}"}
    end
  end

  defp check_number(number, item_name, {:gt, check_value}) do
    check_number(number, item_name, {:greater_than, check_value})
  end

  defp check_number(number, item_name, {:greater_than_or_equal_to, check_value}) do
    if number >= check_value do
      true
    else
      %{item_name => "must be greater than or equal to #{check_value}; got: #{inspect(number)}"}
    end
  end

  defp check_number(number, item_name, {:min, check_value}) do
    check_number(number, item_name, {:greater_than_or_equal_to, check_value})
  end

  defp check_number(number, item_name, {:gte, check_value}) do
    check_number(number, item_name, {:greater_than_or_equal_to, check_value})
  end

  defp check_number(number, item_name, {:less_than, check_value}) do
    if number < check_value do
      true
    else
      %{item_name => "must be less than #{check_value}; got: #{inspect(number)}"}
    end
  end

  defp check_number(number, item_name, {:lt, check_value}) do
    check_number(number, item_name, {:less_than, check_value})
  end

  defp check_number(number, item_name, {:less_than_or_equal_to, check_value}) do
    if number <= check_value do
      true
    else
      %{item_name => "must be less than or equal to #{check_value}; got: #{inspect(number)}"}
    end
  end

  defp check_number(number, item_name, {:lte, check_value}) do
    check_number(number, item_name, {:less_than_or_equal_to, check_value})
  end

  defp check_number(number, item_name, {:max, check_value}) do
    check_number(number, item_name, {:less_than_or_equal_to, check_value})
  end

  defp check_number(_number, item_name, {check, _check_value}) do
    %{item_name => "unknown check '#{check}'"}
  end

  @doc """
  Checks whether an item_name is a memeber of a list.

  ## Examples

      iex> Exop.ValidationChecks.check_in(%{a: 1}, :a, [1, 2, 3])
      true
  """
  @spec check_in(map(), atom() | String.t(), list()) :: true | check_error
  def check_in(check_items, item_name, check_list) when is_list(check_list) do
    check_item = get_check_item(check_items, item_name)

    if Enum.member?(check_list, check_item) do
      true
    else
      %{item_name => "must be one of #{inspect(check_list)}; got: #{inspect(check_item)}"}
    end
  end

  def check_in(_check_items, _item_name, _check_list), do: true

  @doc """
  Checks whether an item_name is not a memeber of a list.

  ## Examples

      iex> Exop.ValidationChecks.check_not_in(%{a: 4}, :a, [1, 2, 3])
      true
  """
  @spec check_not_in(map(), atom() | String.t(), list()) :: true | check_error
  def check_not_in(check_items, item_name, check_list) when is_list(check_list) do
    check_item = get_check_item(check_items, item_name)

    if Enum.member?(check_list, check_item) do
      %{item_name => "must not be included in #{inspect(check_list)}; got: #{inspect(check_item)}"}
    else
      true
    end
  end

  def check_not_in(_check_items, _item_name, _check_list), do: true

  @doc """
  Checks whether an item_name conforms the given format.

  ## Examples

      iex> Exop.ValidationChecks.check_format(%{a: "bar"}, :a, ~r/bar/)
      true
  """
  @spec check_format(map(), atom() | String.t(), Regex.t()) :: true | check_error
  def check_format(check_items, item_name, check) do
    check_item = get_check_item(check_items, item_name)

    if is_binary(check_item) do
      if Regex.match?(check, check_item) do
        true
      else
        %{item_name => "has invalid format.; got: #{inspect(check_item)}"}
      end
    else
      true
    end
  end

  @doc """
  The alias for `check_format/3`.
  Checks whether an item_name conforms the given format.

  ## Examples

      iex> Exop.ValidationChecks.check_regex(%{a: "bar"}, :a, ~r/bar/)
      true
  """
  @spec check_regex(map(), atom() | String.t(), Regex.t()) :: true | check_error
  def check_regex(check_items, item_name, check) do
    check_format(check_items, item_name, check)
  end

  @doc """
  Checks an item_name over length constraints.

  ## Examples

      iex> Exop.ValidationChecks.check_length(%{a: "123"}, :a, %{min: 0})
      [true]

      iex> Exop.ValidationChecks.check_length(%{a: ~w(1 2 3)}, :a, %{in: 2..4})
      [true]

      iex> Exop.ValidationChecks.check_length(%{a: ~w(1 2 3)}, :a, %{is: 3, max: 4})
      [true, true]
  """
  @spec check_length(map(), atom() | String.t(), map()) :: true | [check_error]
  def check_length(check_items, item_name, checks) do
    check_item = get_check_item(check_items, item_name)

    actual_length = get_length(check_item)

    for {check, check_value} <- checks, into: [] do
      check_length(check, item_name, actual_length, check_value)
    end
  end

  @spec get_length(any) :: pos_integer() | {:error, :wrong_type}
  defp get_length(param) when is_list(param), do: length(param)
  defp get_length(param) when is_binary(param), do: String.length(param)
  defp get_length(param) when is_atom(param), do: param |> Atom.to_string() |> get_length()
  defp get_length(param) when is_map(param), do: param |> Map.keys() |> get_length()
  defp get_length(param) when is_tuple(param), do: tuple_size(param)
  defp get_length(_param), do: {:error, :wrong_type}

  @spec check_length(atom(), atom() | String.t(), pos_integer | {:error, :wrong_type}, number) ::
          true | check_error
  defp check_length(_check, item_name, {:error, :wrong_type}, _check_value) do
    %{item_name => "length check supports only lists, binaries, atoms, maps and tuples"}
  end

  defp check_length(:min, item_name, actual_length, check_value) do
    check_length(:gte, item_name, actual_length, check_value)
  end

  defp check_length(:gte, item_name, actual_length, check_value) do
    actual_length >= check_value ||
      %{
        item_name =>
          "length must be greater than or equal to #{check_value}; got length: #{
            inspect(actual_length)
          }"
      }
  end

  defp check_length(:gt, item_name, actual_length, check_value) do
    actual_length > check_value ||
      %{
        item_name =>
          "length must be greater than #{check_value}; got length: #{inspect(actual_length)}"
      }
  end

  defp check_length(:max, item_name, actual_length, check_value) do
    check_length(:lte, item_name, actual_length, check_value)
  end

  defp check_length(:lte, item_name, actual_length, check_value) do
    actual_length <= check_value ||
      %{
        item_name =>
          "length must be less than or equal to #{check_value}; got length: #{
            inspect(actual_length)
          }"
      }
  end

  defp check_length(:lt, item_name, actual_length, check_value) do
    actual_length < check_value ||
      %{
        item_name =>
          "length must be less than #{check_value}; got length: #{inspect(actual_length)}"
      }
  end

  defp check_length(:is, item_name, actual_length, check_value) do
    actual_length == check_value ||
      %{
        item_name => "length must be equal to #{check_value}; got length: #{inspect(actual_length)}"
      }
  end

  defp check_length(:in, item_name, actual_length, check_value) do
    Enum.member?(check_value, actual_length) ||
      %{
        item_name => "length must be in range #{check_value}; got length: #{inspect(actual_length)}"
      }
  end

  defp check_length(check, item_name, _actual_length, _check_value) do
    %{item_name => "unknown check '#{check}'"}
  end

  @doc """
  Checks whether an item is expected structure.

  ## Examples

      defmodule SomeStruct1, do: defstruct [:a, :b]
      defmodule SomeStruct2, do: defstruct [:b, :c]

      Exop.ValidationChecks.check_struct(%{a: %SomeStruct1{}}, :a, %SomeStruct1{})
      # true
      Exop.ValidationChecks.check_struct(%{a: %SomeStruct1{}}, :a, %SomeStruct2{})
      # false
  """
  @spec check_struct(map(), atom() | String.t(), struct()) :: true | check_error
  def check_struct(check_items, item_name, check) do
    check_items
    |> get_check_item(item_name)
    |> validate_struct(check, item_name)
  end

  @doc """
  Checks whether an item is valid over custom validation function.

  ## Examples

      iex> Exop.ValidationChecks.check_func(%{a: 1}, :a, fn({:a, value}, _all_param)-> value > 0 end)
      true
      iex> Exop.ValidationChecks.check_func(%{a: 1}, :a, fn({:a, _value}, _all_param)-> :ok end)
      true
      iex> Exop.ValidationChecks.check_func(%{a: 1}, :a, fn({:a, value}, _all_param)-> is_nil(value) end)
      %{a: "not valid"}
      iex> Exop.ValidationChecks.check_func(%{a: 1}, :a, fn({:a, _value}, _all_param)-> :error end)
      %{a: "not valid"}
      iex> Exop.ValidationChecks.check_func(%{a: -1}, :a, fn({:a, _value}, _all_param)-> {:error, :my_error} end)
      %{a: :my_error}
  """
  @spec check_func(
          map(),
          atom() | String.t(),
          ({atom() | String.t(), any()}, map() -> any())
        ) :: true | check_error
  def check_func(check_items, item_name, check) do
    check_item = get_check_item(check_items, item_name)

    check_result = check.({item_name, check_item}, check_items)

    case check_result do
      {:error, msg} -> %{item_name => msg}
      check_result when check_result in [false, :error] -> %{item_name => "not valid"}
      _ -> true
    end
  end

  @doc """
  Checks whether a parameter's value exactly equals given value (with type equality).

  ## Examples

      iex> Exop.ValidationChecks.check_equals(%{a: 1}, :a, 1)
      true
  """
  @spec check_equals(map(), atom() | String.t(), any()) :: true | check_error
  def check_equals(check_items, item_name, check_value) do
    check_item = get_check_item(check_items, item_name)

    if check_item === check_value do
      true
    else
      %{item_name => "must be equal to #{inspect(check_value)}; got: #{inspect(check_item)}"}
    end
  end

  @doc """
  The alias for `check_equals/3`.
  Checks whether a parameter's value exactly equals given value (with type equality).

  ## Examples

      iex> Exop.ValidationChecks.check_exactly(%{a: 1}, :a, 1)
      true
  """
  @spec check_exactly(map(), atom() | String.t(), any()) :: true | check_error
  def check_exactly(check_items, item_name, check_value) do
    check_equals(check_items, item_name, check_value)
  end

  @spec check_allow_nil(map(), atom() | String.t(), boolean()) :: true | check_error
  def check_allow_nil(_check_items, _item_name, true), do: true

  def check_allow_nil(check_items, item_name, false) do
    check_item = get_check_item(check_items, item_name)

    !is_nil(check_item) || %{item_name => "doesn't allow nil"}
  end

  @spec check_subset_of(map(), atom() | String.t(), list()) :: true | check_error
  def check_subset_of(check_items, item_name, check_list) when is_list(check_list) do
    check_item = get_check_item(check_items, item_name)

    cond do
      is_list(check_item) and length(check_item) > 0 ->
        case check_item -- check_list do
          [] ->
            true

          _ ->
            %{
              item_name => "must be a subset of #{inspect(check_list)}; got: #{inspect(check_item)}"
            }
        end

      is_list(check_item) and length(check_item) == 0 ->
        %{
          item_name => "must be a subset of #{inspect(check_list)}; got: #{inspect(check_item)}"
        }

      not is_list(check_item) ->
        %{
          item_name => "must be a list; got: #{inspect(check_item)}"
        }
    end
  end

  @spec validate_struct(any(), any(), atom() | String.t()) :: boolean()
  defp validate_struct(%struct{}, %struct{}, _item_name), do: true

  defp validate_struct(%struct{}, struct, _item_name) when is_atom(struct), do: true

  defp validate_struct(%struct{}, check_struct, item_name) when is_atom(check_struct) do
    %{
      item_name =>
        "is not expected struct; expected: #{inspect(check_struct)}; got: #{inspect(struct)}"
    }
  end

  defp validate_struct(item, check_struct, item_name) when is_atom(item) do
    %{
      item_name =>
        "is not expected struct; expected: #{inspect(check_struct)}; got: #{inspect(item)}"
    }
  end

  defp validate_struct(%struct{} = _item, %check_struct{}, item_name) do
    %{
      item_name =>
        "is not expected struct; expected: #{inspect(check_struct)}; got: #{inspect(struct)}"
    }
  end

  defp validate_struct(item, check_struct, item_name) do
    %{
      item_name =>
        "is not expected struct; expected: #{inspect(check_struct)}; got: #{inspect(item)}"
    }
  end
end
