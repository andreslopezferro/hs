defmodule HS do
  @moduledoc """
  Documentation for Hs.
  """

  def describe_product(desc) do
    Census.describe_product(desc)
    |> response_format()
  end

  def answer_question(tx_id, int_id, answer) do
    Census.answer_question(tx_id, int_id, answer)
    |> response_format()
  end

  def answer_valued_question(tx_id, int_id, answer) do
    Census.answer_valued_question(tx_id, int_id, answer)
    |> response_format()
  end

  def get_schedule_list(hs_code) do
    body = Census.get_schedule_list(hs_code)
    {:schedule_list, body}
  end

  def get_legal_notes(hs_code) do
    body = Census.get_legal_notes(hs_code)
    {:notes, body}
  end

  # private

  defp response_format(%{"hsCode" => hs_code} = body)  when hs_code != "" do
    product = %{}
      |> Map.put(:hs_code, hs_code)
      |> Map.put(:current_item_name, body["currentItemName"])
      |> Map.put(:characteristics, %{assumed: body["assumedInteractions"], known: body["knownInteractions"]})
    {:ok, body["txId"], product}
  end
  defp response_format(%{"currentItemName" => currentItemName} = body) when currentItemName == "Unknown Item" do
    product = %{}
      |> Map.put(:current_item_name, body["currentItemName"])
    {:error, body["txId"], product}
  end
  defp response_format(%{"multiItemError" => multiItemError} = body) when multiItemError == true do
    product = %{}
      |> Map.put(:current_item_name, body["currentItemName"])
      |> Map.put(:multi_item_error, body["multiItemError"])
    {:error, body["txId"], product}
  end
  defp response_format(%{"currentQuestionInteraction" => %{"type" => "VALUED"}} = body) do
    {:valued_question, body["txId"], body["currentQuestionInteraction"]["id"], question_response_format(body)}
  end
  defp response_format(body) do
    {:question, body["txId"], body["currentQuestionInteraction"]["id"],  question_response_format(body)}
  end

  defp question_response_format(body) do
    %{}
    |> Map.put(:current_item_name, body["currentItemName"])
    |> Map.put(:characteristics, %{assumed: body["assumedInteractions"], known: body["knownInteractions"]})
    |> Map.put(:question, questions(body))
    |> Map.put(:label, body["currentQuestionInteraction"]["label"])
    |> Map.put(:type, body["currentQuestionInteraction"]["type"])
  end

  defp questions(body) do
    body["currentQuestionInteraction"]["attrs"]
    |> Enum.reduce([], fn(x, acc) ->
      question = %{name: x["name"], id: x["id"], value: x["value"]}
      [question | acc]
    end)
  end
end
