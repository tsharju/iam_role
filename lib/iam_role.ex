defmodule IamRole do
  use Application
  
  defmodule Info do
    defstruct last_updated: nil, arn: nil, id: nil, name: nil
    @type t :: %Info{last_updated: binary, arn: binary, id: binary}
  end

  defmodule Credentials do
    defstruct(last_updated: nil, type: nil, access_key_id: nil,
              secret_access_key: nil, token: nil, expiration: nil)
    @type t :: %Credentials{last_updated: binary, type: binary,
                            access_key_id: binary, secret_access_key: binary,
                            token: binary, expiration: binary}
  end
  
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(IamRole.Worker, [[]]),
    ]

    opts = [strategy: :one_for_one, name: IamRole.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get_state() do
    GenServer.call(IamRole.Worker, :get_state)
  end
  
  def get_credentials() do
    Application.get_env(:iam_role, :credentials)
  end
  
end
