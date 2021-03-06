defmodule Census do
  def describe_product(desc) do
    census_request_template()
      |> Map.put(:state, "start")
      |> Map.put(:proddesc, desc)
      |> Poison.encode!()
      |> run_request("post", "https://uscensus.prod.3ceonline.com/ui/classify")
  end

  def answer_valued_question(tx_id, int_id, answer) do
    census_request_template()
      |> Map.merge(%{
        state: "continue",
        interactionid: int_id,
        txid: tx_id,
        values: answer,
      })
      |> Poison.encode!()
      |> run_request("post", "https://uscensus.prod.3ceonline.com/ui/classify")
  end

  def answer_question(tx_id, int_id, answer) do
    [key | _] = Map.keys(answer)
    answer = [%{
      first: answer[key],
      second: key
    }]
    answer_valued_question(tx_id, int_id, answer)
  end

  def get_schedule_list(hs_code) do
    run_request("", "get", "https://uscensus.prod.3ceonline.com/ui/tradedata/export/schedule/find/#{hs_code}/US/US/true")
  end

  def get_legal_notes(hs_code) do
    run_request("", "get", "https://uscensus.prod.3ceonline.com/ui/apis/notes/v1/find/export/US/en/#{hs_code}")
  end

  defp census_request_template do
    %{
      destination: "US",
      lang: "en",
      origin: "US",
      proddesc: "spoon",
      profileId: "57471f0c4ac2c9b910000000",
      schedule: "import/export",
      state: "start",
      stopAtHS6: "Y",
      username: "NOT_SET",
      userData: "NO_DATA_AVAIL"
    }
  end

  defp run_request(request, method, url) do
    {:ok, %HTTPoison.Response{body: body, headers: _headers}} = response = HTTPoison.request(method, url, request, [{"Content-Type", "application/json"}], [timeout: 50_000, recv_timeout: 50_000, hackney: [cookie: [get_cookie()]]])
    body = Poison.decode!(body)
    case Map.has_key?(body, "data") do
      true -> body["data"]
      _ -> body
    end
  end

  def get_cookie do
    {:ok, %HTTPoison.Response{headers: headers}} = HTTPoison.get("https://uscensus.prod.3ceonline.com/")
    {"set-cookie", cookie} = Enum.find(headers, nil, fn(x) ->  do_get_cookie(x) end)
    cookie
  end

  defp do_get_cookie({"set-cookie", _}), do: true
  defp do_get_cookie(_), do: false
end
