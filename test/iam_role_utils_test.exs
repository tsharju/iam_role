defmodule IamRoleUtilsTest do
  use ExUnit.Case

  alias IamRole.Utils
  
  test "parse valid info" do
    info = ~s({"Code" : "Success",
               "LastUpdated" : "2015-10-23T05:28:50Z",
               "InstanceProfileArn" : "arn:aws:iam::000000000000:instance-profile/role-name",
               "InstanceProfileId" : "XXXXXXXXXXXXXXXXXXXXX"}) |> Utils.parse_info

    assert info.id           == "XXXXXXXXXXXXXXXXXXXXX"
    assert info.arn          ==  "arn:aws:iam::000000000000:instance-profile/role-name"
    assert info.last_updated == "2015-10-23T05:28:50Z"
    assert info.name         == "role-name"
  end

  test "parse info invalid json" do
    :error = Utils.parse_info("{")
  end

  test "parse info missing keys" do
    assert_raise KeyError, fn ->
      Utils.parse_info(
        ~s({"Code" : "Success",
            "LastUpdated" : "2015-10-23T05:28:50Z",
            "InstanceProfileId" : "XXXXXXXXXXXXXXXXXXXXX"}))
    end
  end

  test "parse valid credentials" do
    credentials = ~s({"Code" : "Success",
                      "LastUpdated" : "2015-10-23T07:28:07Z",
                      "Type" : "AWS-HMAC",
                      "AccessKeyId" : "...",
                      "SecretAccessKey" : "...",
                      "Token" : "...",
                      "Expiration" : "2015-10-23T13:47:29Z"}) |> Utils.parse_credentials

    assert credentials.last_updated      == "2015-10-23T07:28:07Z"
    assert credentials.type              == "AWS-HMAC"
    assert credentials.access_key_id     == "..."
    assert credentials.secret_access_key == "..."
    assert credentials.token             == "..."
    assert credentials.expiration        == "2015-10-23T13:47:29Z"
  end
  
  test "parse credentials invalid json" do
    :error = Utils.parse_credentials("{")
  end

  test "parse credentials missing keys" do
    assert_raise KeyError, fn ->
      Utils.parse_credentials(
        ~s({"Code" : "Success",
            "LastUpdated" : "2015-10-23T07:28:07Z",
            "AccessKeyId" : "...",
            "SecretAccessKey" : "...",
            "Token" : "...",
            "Expiration" : "2015-10-23T13:47:29Z"}))
    end
  end

  test "parse date" do
    date = Utils.date_now_diff("2015-10-23T13:47:29Z")
    
    assert date > 0
  end
  
end
