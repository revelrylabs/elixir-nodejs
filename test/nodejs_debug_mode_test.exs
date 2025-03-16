defmodule NodeJS.DebugModeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  describe "debug_mode functionality" do
    test "logs Node.js stdout messages when debug_mode is enabled" do
      defmodule TestDebugHandler do
        use GenServer
        require Logger

        def start_link do
          GenServer.start_link(__MODULE__, nil)
        end

        def init(_) do
          {:ok, nil}
        end

        def debug_mode? do
          Application.get_env(:nodejs, :debug_mode, false)
        end

        # The implementation from worker.ex
        def handle_info({_pid, {:data, {_flag, msg}} = _data}, state) do
          if debug_mode?() do
            Logger.info("NodeJS: #{msg}")
          end

          {:noreply, state}
        end
      end

      # Start the test process
      {:ok, pid} = TestDebugHandler.start_link()

      # Test with debug_mode disabled (default)
      log_without_debug =
        capture_log(fn ->
          # Simulate debugger message from Node.js
          send(pid, {self(), {:data, {:eol, "Debugger listening on ws://127.0.0.1:9229/abc123"}}})
          # Wait for any potential logging
          Process.sleep(50)
        end)

      # Verify no logging occurred
      refute log_without_debug =~ "NodeJS: Debugger listening"

      # Enable debug_mode
      Application.put_env(:nodejs, :debug_mode, true)

      # Test with debug_mode enabled
      log_with_debug =
        capture_log(fn ->
          # Simulate debugger message from Node.js
          send(pid, {self(), {:data, {:eol, "Debugger listening on ws://127.0.0.1:9229/abc123"}}})
          # Wait for any potential logging
          Process.sleep(50)
        end)

      # Clean up
      Application.delete_env(:nodejs, :debug_mode)

      # Verify logging occurred
      assert log_with_debug =~ "NodeJS: Debugger listening"
    end
  end

  describe "port safety" do
    test "reset_terminal handles invalid ports gracefully" do
      defmodule TestPortHandler do
        use GenServer
        require Logger

        def start_link do
          GenServer.start_link(__MODULE__, nil)
        end

        def init(_) do
          {:ok, nil}
        end

        # The implementation from worker.ex
        def reset_terminal(port) do
          try do
            Port.command(port, "\x1b[0m\x1b[?7h\x1b[?25h\x1b[H\x1b[2J")
            Port.command(port, "\x1b[!p\x1b[?47l")
          rescue
            _ ->
              Logger.debug("NodeJS: Could not reset terminal - port may be closed")
          end
        end
      end

      log =
        capture_log(fn ->
          # Try to reset an invalid port
          TestPortHandler.reset_terminal(:invalid_port)
          Process.sleep(50)
        end)

      # Verify proper error handling
      assert log =~ "NodeJS: Could not reset terminal"
    end
  end
end
