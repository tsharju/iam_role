defmodule IamRole.Worker do
  use GenServer

  alias IamRole.Utils
  
  @metadata_host    "169.254.169.254"
  @metadata_version "2014-11-05"
  @initial_state    %{role_info: nil, credentials: nil}
  
  def start_link(args) do
    GenServer.start_link(__MODULE__, [args], [])
  end
  
  def init([args]) do
    state = update(@initial_state)
    {:ok, state}
  end

  def handle_info(:refresh, state) do
    state = update(state)
    {:noreply, state}
  end

  ## Internal API
  
  defp update(%{role_info: info} = state) do
    info_uri = "http://#{@metadata_host}/#{@metadata_version}/meta-data/iam/info/"
    |> String.to_char_list

    # load role info
    if info == nil do
      case http_request(info_uri) do
        :error ->
          # maybe retry
          :ok
        body ->
          case Utils.parse_info(body) do
            :error ->
              # maybe retry
              :ok
            info ->
              state = %{state | role_info: info}
          end
      end
    end
    
    role_name = state.role_info.name
    credentials_uri = "http://#{@metadata_host}/#{@metadata_version}" <>
      "/meta-data/iam/security-credentials/#{role_name}" |> String.to_char_list
    
    # load role credentials
    case http_request(credentials_uri) do
      :error ->
        # maybe retry
        :ok
      body ->
        case Utils.parse_credentials(body) do
          :error ->
            # maybe retry
            :ok
          credentials ->
            # schedule credential refresh
            seconds = Utils.date_now_diff(credentials.expiration) - 180 # 3 minutes before
            Process.send_after(self, :refresh, seconds * 1000)
                
            state = %{state | credentials: credentials}            
        end
    end
    
    state
  end
  
  defp http_request(uri) do
    case :httpc.request(:get, {uri, []}, [timeout: 5000], [body_format: :binary]) do
      {:ok, {{_, 200, _}, _, body}} ->
        body
      {:ok, {{_, _, _}, _, _}} ->
        :error
      {:error, _} ->
        :error
    end
  end
  
end
