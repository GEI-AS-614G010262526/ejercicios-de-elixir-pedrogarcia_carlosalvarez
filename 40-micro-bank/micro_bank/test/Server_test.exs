defmodule Server_Test do
  use ExUnit.Case, async: true

  alias Server

  setup do
    {:ok, _pid} = Server.start_link([{:account1, 100}, {:account2, 200}])
    :ok
  end

  test "deposit increases the balance" do
    assert {:ok, 150} = Server.deposit(:account1, 50)
    assert {:ok, 150} = Server.ask(:account1)
    assert {:ok, 200} = Server.ask(:account2)
  end

  test "withdraw decreases the balance" do
    assert {:ok, 150} = Server.withdraw(:account2, 50)
    assert {:error, :insufficient_funds} = Server.withdraw(:account1, 200)
  end

  test "ask returns the correct balance" do
    assert {:ok, 100} = Server.ask(:account1)
    assert {:ok, 200} = Server.ask(:account2)
    assert {:error, :not_found} = Server.ask(:non_existent_account)
  end

  test "deposit fails for non-existent account" do
    assert {:error, :not_found} = Server.deposit(:non_existent_account, 50)
  end

  test "withdraw fails for non-existent account" do
    assert {:error, :not_found} = Server.withdraw(:non_existent_account, 50)
  end

  test "stop the server" do
    assert :ok = Server.stop()
  end
end
