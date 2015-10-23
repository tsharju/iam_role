ExUnit.start()

defmodule IamRoleTest.HttpClient do
  def request(:get, {'http://169.254.169.254/2014-11-05/meta-data/iam/info/', []}, _, _) do
    body = ~s({"Code" : "Success",
               "LastUpdated" : "2015-10-23T05:28:50Z",
               "InstanceProfileArn" : "arn:aws:iam::000000000000:instance-profile/role-name",
               "InstanceProfileId" : "XXXXXXXXXXXXXXXXXXXXX"})
    {:ok, {{'HTTP/1.1', 200, 'OK'}, [], body}}
  end
end
