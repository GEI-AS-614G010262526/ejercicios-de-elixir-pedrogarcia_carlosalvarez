defmodule ServerSupervisor_Test do
  use ExUnit.Case, async: false

  setup do
    {:ok, sup} = ServerSupervisor.start_link([{:alice, 100}])
    on_exit(fn -> Process.exit(sup, :exit) end)

    server_pid = wait_for_server()
    {:ok, sup: sup, server: server_pid}
  end

  test "restarts the server when it crashes", %{server: old_pid} do
    assert is_pid(old_pid)

    # Simulate crash
    Process.exit(old_pid, :kill)

    assert not Process.alive?(old_pid)

    new_pid = wait_for_server()
    assert is_pid(new_pid)
    assert new_pid != old_pid

    # Ensure state preserved by restart of the GenServer (accounts initialized)
    assert {:ok, 100} = GenServer.call(Server, {:ask, :alice})
  end

  test "does not restart when stopped normally" do
    assert is_pid(Process.whereis(Server))

    # Stop the server normally via its API
    Server.stop()

    # Give the supervisor a moment to react
    :timer.sleep(50)

    # Server should not be running after a normal stop (restart: :transient)
    assert Process.whereis(Server) == nil
  end

  # Helper: wait for the registered Server process to appear
  defp wait_for_server(retries \\ 20)
  defp wait_for_server(0), do: flunk("Server did not start")
  defp wait_for_server(retries) do
    case Process.whereis(Server) do
      pid when is_pid(pid) -> pid
      nil ->
        :timer.sleep(10)
        wait_for_server(retries - 1)
    end
  end
end
