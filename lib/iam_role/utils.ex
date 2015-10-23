defmodule IamRole.Utils do

  alias IamRole.Info
  alias IamRole.Credentials
  
  def parse_info(info) do
    case :jsone.try_decode(info) do
      {:ok, info, ""} ->
        arn          = Dict.fetch!(info, "InstanceProfileArn")
        id           = Dict.fetch!(info, "InstanceProfileId")
        last_updated = Dict.fetch!(info, "LastUpdated")
        
        # parse the role name from arn
        [_, name] = String.split(arn, "/", parts: 2)
        
        %Info{arn: arn, id: id, last_updated: last_updated, name: name}
      {:error, _} ->
        :error
    end
  end
  
  def parse_credentials(credentials) do
    case :jsone.try_decode(credentials) do
      {:ok, credentials, ""} ->
        last_updated      = Dict.fetch!(credentials, "LastUpdated")
        type              = Dict.fetch!(credentials, "Type")
        access_key_id     = Dict.fetch!(credentials, "AccessKeyId")
        secret_access_key = Dict.fetch!(credentials, "SecretAccessKey")
        token             = Dict.fetch!(credentials, "Token")
        expiration        = Dict.fetch!(credentials, "Expiration")
        
        %Credentials{last_updated: last_updated, type: type, access_key_id: access_key_id,
                     secret_access_key: secret_access_key, token: token, expiration: expiration}
      {:error, _} ->
        :error
    end
  end

  def date_now_diff(date) do
    [_, year, month, day, hour, minute, second] =
      Regex.run(~r/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/, date)
    date = {{String.to_integer(year),
             String.to_integer(month),
             String.to_integer(day)},
            {String.to_integer(hour),
             String.to_integer(minute),
             String.to_integer(second)}}
    now = :calendar.now_to_universal_time(:erlang.timestamp)
    {days, {hours, mins, secs}} = :calendar.time_difference(now, date)

    # return seconds
    days * 24 * 3600 + hours * 3600 + mins * 60 + secs
  end
  
end
