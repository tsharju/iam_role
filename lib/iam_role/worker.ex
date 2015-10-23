defmodule IamRole.Worker do
  use GenServer

  require Logger
  
  alias IamRole.Utils
  alias IamRole.Info
  alias IamRole.Credentials
  
  @metadata_host    "169.254.169.254"
  @metadata_version "2014-11-05"
  @initial_state    %{role_info: nil, credentials: nil}
  
  def start_link(args) do
    GenServer.start_link(__MODULE__, [args], name: __MODULE__)
  end
  
  def init([_args]) do
    # if updates are disabled read key and secret from system env
    disabled = Application.get_env(:iam_role, :disabled, false)
    if disabled do
      access_key_id     = System.get_env("AWS_ACCESS_KEY_ID") || ""
      secret_access_key = System.get_env("AWS_SECRET_ACCESS_KEY") || ""
      credentials       = %Credentials{access_key_id: access_key_id,
                                       secret_access_key: secret_access_key}

      # store credentials to app env
      :ok = Application.put_env(:iam_role,
                                :credentials,
                                {credentials.access_key_id,
                                 credentials.secret_access_key})
      
      {:ok, %{@initial_state | role_info: %Info{}, credentials: credentials}}
    else
      case update_info(@initial_state) do
        :error ->
          # stop here, supervisor will let us retry
          {:stop, :could_not_update_role_info}
        state ->
          {:ok, state, 0}
      end
    end
  end
  
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:timeout, state) do
    # trigger credential refresh
    Process.send_after(self, :refresh, 0)
    {:noreply, state}
  end
  
  def handle_info(:refresh, state) do
    Logger.debug "Refreshing IAM role credentials."
    {:noreply, update_credentials(state)}
  end

  ## Internal API
  
  defp update_info(%{role_info: nil} = state) do
    info_uri = "http://#{@metadata_host}/#{@metadata_version}/meta-data/iam/info/"
    |> String.to_char_list
    
    # load role info
    case http_request(info_uri) do
      :error ->
        # maybe retry
        :error
      body ->
        case Utils.parse_info(body) do
          :error ->
            # maybe retry
            :error
          info ->
            %{state | role_info: info}
        end
    end
  end
  
  defp update_credentials(%{role_info: role_info} = state) do
    role_name = role_info.name
    credentials_uri = "http://#{@metadata_host}/#{@metadata_version}" <>
      "/meta-data/iam/security-credentials/#{role_name}" |> String.to_char_list
    
    # load role credentials
    case http_request(credentials_uri) do
      :error ->
        # retry
        Process.send_after(self, :refresh, 500)
      body ->
        case Utils.parse_credentials(body) do
          :error ->
            # retry
            Process.send_after(self, :refresh, 500)
          credentials ->
            # schedule credential refresh
            seconds = Utils.date_now_diff(credentials.expiration) - 180 # 3 minutes before
            Process.send_after(self, :refresh, seconds * 1000)

            # publish credentials to env
            :ok = Application.put_env(:iam_role, :credentials,
                                      {credentials.access_key_id, credentials.secret_access_key})
            
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
