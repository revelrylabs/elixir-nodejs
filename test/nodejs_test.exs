defmodule NodeJS.Test do
  use ExUnit.Case, async: true
  doctest NodeJS

  setup do
    path =
      __ENV__.file
      |> Path.dirname()
      |> Path.join("js")

    start_supervised({NodeJS.Supervisor, path: path})

    :ok
  end

  defp js_error_message(msg) do
    msg
    |> String.split("\n")
    |> case do
      [_head, js_error | _tail] -> js_error
    end
    |> String.trim()
  end

  describe "large payload" do
    test "does not explode" do
      NodeJS.call!({"keyed-functions", "getBytes"}, [128_000])
    end
  end

  describe "calling default-function-echo" do
    test "returns first arg" do
      assert 1 == NodeJS.call!("default-function-echo", [1])
      assert "two" == NodeJS.call!("default-function-echo", ["two"])
      assert %{"three" => 3} == NodeJS.call!("default-function-echo", [%{three: 3}])
      assert nil == NodeJS.call!("default-function-echo")
      assert 5 == NodeJS.call!({"default-function-echo"}, [5])
    end
  end

  describe "calling keyed-functions hello" do
    test "replies" do
      assert "Hello, Joel!" == NodeJS.call!({"keyed-functions", "hello"}, ["Joel"])
    end
  end

  describe "calling keyed-functions math.add and math.sub" do
    test "returns correct values" do
      assert 2 == NodeJS.call!({"keyed-functions", "math", "add"}, [1, 1])
      assert 1 == NodeJS.call!({"keyed-functions", "math", "sub"}, [2, 1])
      assert 2 == NodeJS.call!({"keyed-functions", :math, :add}, [1, 1])
      assert 1 == NodeJS.call!({"keyed-functions", :math, :sub}, [2, 1])
    end
  end

  describe "calling keyed-functions throwTypeError" do
    test "returns TypeError" do
      assert {:error, msg} = NodeJS.call({"keyed-functions", :throwTypeError})
      assert js_error_message(msg) === "TypeError: oops"
    end

    test "with call! raises error" do
      assert_raise NodeJS.Error, fn ->
        NodeJS.call!({"keyed-functions", :oops})
      end
    end
  end

  describe "calling keyed-functions getIncompatibleReturnValue" do
    test "returns a JSON.stringify error" do
      assert {:error, msg} = NodeJS.call({"keyed-functions", :getIncompatibleReturnValue})
      assert msg =~ "Converting circular structure to JSON"
    end
  end

  describe "calling things that are not functions: " do
    test "module does not exist" do
      assert {:error, msg} = NodeJS.call("idontexist")
      assert msg =~ "Error: Cannot find module 'idontexist'"
    end

    test "function does not exist" do
      assert {:error, msg} = NodeJS.call({"keyed-functions", :idontexist})

      assert js_error_message(msg) ===
               "Error: Could not find function 'idontexist' in module 'keyed-functions'"
    end

    test "object does not exist" do
      assert {:error, msg} = NodeJS.call({"keyed-functions", :idontexist, :foo})

      assert js_error_message(msg) ===
               "TypeError: Cannot read properties of undefined (reading 'foo')"
    end
  end

  describe "calling function re-exported from an NPM dependency" do
    test "uuid" do
      assert {:ok, _uuid} = NodeJS.call({"keyed-functions", :uuid})
    end
  end

  describe "calling a function in a subdirectory index.js" do
    test "subdirectory" do
      assert {:ok, true} = NodeJS.call("subdirectory")
    end
  end

  describe "calling functions that return promises" do
    test "gets resolved value" do
      assert {:ok, 1234} = NodeJS.call("slow-async-echo", [1234])
    end

    test "doesn't cause responses to be delivered out of order" do
      task1 =
        Task.async(fn ->
          NodeJS.call("slow-async-echo", [1111])
        end)

      task2 =
        Task.async(fn ->
          NodeJS.call("default-function-echo", [2222])
        end)

      assert {:ok, 2222} = Task.await(task2)
      assert {:ok, 1111} = Task.await(task1)
    end

    test "can't block js workers" do
      own_pid = self()

      # Call a few js functions that are slow to reply
      task1 =
        Task.async(fn ->
          res = NodeJS.call("slow-async-echo", [1111, 60_000], timeout: 1)
          Process.send(own_pid, :received_timeout_1, [])
          res
        end)

      task2 =
        Task.async(fn ->
          res = NodeJS.call("slow-async-echo", [1112, 60_000], timeout: 1)
          Process.send(own_pid, :received_timeout_2, [])
          res
        end)

      task3 =
        Task.async(fn ->
          res = NodeJS.call("slow-async-echo", [1113, 60_000], timeout: 1)
          Process.send(own_pid, :received_timeout_3, [])
          res
        end)

      task4 =
        Task.async(fn ->
          res = NodeJS.call("slow-async-echo", [1114, 60_000], timeout: 1)
          Process.send(own_pid, :received_timeout_4, [])
          res
        end)

      # After 10ms, we definitely should have received all timeout messages
      assert_receive :received_timeout_1, 10
      assert_receive :received_timeout_2, 10
      assert_receive :received_timeout_3, 10
      assert_receive :received_timeout_4, 10

      assert {:error, "Call timed out."} = Task.await(task1)
      assert {:error, "Call timed out."} = Task.await(task2)
      assert {:error, "Call timed out."} = Task.await(task3)
      assert {:error, "Call timed out."} = Task.await(task4)

      # We should still get an answer here, before the timeout
      assert {:ok, 1115} = NodeJS.call("slow-async-echo", [1115, 1])
    end
  end

  describe "overriding call timeout" do
    test "works, and you can tell because the slow function will time out" do
      assert {:error, "Call timed out."} = NodeJS.call("slow-async-echo", [1111], timeout: 0)
      assert_raise NodeJS.Error, fn -> NodeJS.call!("slow-async-echo", [1111], timeout: 0) end
      assert {:ok, 1111} = NodeJS.call("slow-async-echo", [1111])
    end
  end

  describe "strange characters" do
    test "are transferred properly between js and elixir" do
      assert {:ok, "’"} = NodeJS.call("default-function-echo", ["’"], binary: true)
    end
  end

  describe "Implementation details shouldn't leak:" do
    test "Timeouts do not send stray messages to calling process" do
      assert {:error, "Call timed out."} = NodeJS.call("slow-async-echo", [1111], timeout: 0)

      refute_receive {_ref, {:error, "Call timed out."}}, 50
    end

    test "Crashes do not bring down the calling process" do
      own_pid = self()

      Task.async(fn ->
        {:error, _err} = NodeJS.call("slow-async-echo", [1111])
        # Make sure we reach this line
        Process.send(own_pid, :received_error, [])
      end)

      # Abuse internal APIs / implementation details to find and kill the worker process.
      # Since we don't know which is which, we just kill them all.
      [{_, child_pid, _, _} | _rest] = Supervisor.which_children(NodeJS.Supervisor)
      workers = GenServer.call(child_pid, :get_all_workers)

      Enum.each(workers, fn {_, worker_pid, _, _} ->
        Process.exit(worker_pid, :kill)
      end)

      assert_receive :received_error, 50
    end
  end

  describe "console.log statements" do
    test "don't crash NodeJS process" do
      assert {:ok, 42} = NodeJS.call({"keyed-functions", :logsSomething}, [])
    end
  end

  describe "importing esm module" do
    test "works if module is available in path" do
      result = NodeJS.call({"./esm-module.mjs", :hello}, ["world"], esm: true)
      assert {:ok, "Hello, world!"} = result
    end

    test "can import exported library function" do
      assert {:ok, _uuid} = NodeJS.call({"esm-module.mjs", :uuid}, [], esm: true)
    end

    test "using mjs extension makes esm: true obsolete" do
      assert {:ok, _uuid} = NodeJS.call({"esm-module.mjs", :uuid})
    end

    test "returned promises are resolved" do
      assert {:ok, _uuid} = NodeJS.call({"esm-module.mjs", :echo}, ["1"])
    end

    test "fails if extension is not specified" do
      assert {:error, msg} = NodeJS.call({"esm-module", :hello}, ["me"], esm: true)
      assert js_error_message(msg) =~ "Cannot find module"
    end

    test "fails if file not found" do
      assert {:error, msg} = NodeJS.call({"nonexisting.js", :hello}, [], esm: true)
      assert js_error_message(msg) =~ "Cannot find module"
    end

    test "fails if file has errors" do
      assert {:error, msg} = NodeJS.call({"esm-module-invalid.mjs", :hello})
      assert js_error_message(msg) =~ "ReferenceError: require is not defined in ES module scope"
    end
  end

  describe "terminal handling" do
    test "handles ANSI sequences without corrupting protocol" do
      # Test basic ANSI handling - protocol messages should work
      assert {:ok, "clean output"} = NodeJS.call({"terminal-test", "outputWithANSI"})

      # Test complex ANSI sequences - protocol messages should work
      assert {:ok, "complex test passed"} = NodeJS.call({"terminal-test", "complexOutput"})

      # Test multiple processes don't interfere with each other
      tasks =
        for _ <- 1..4 do
          Task.async(fn ->
            NodeJS.call({"terminal-test", "outputWithANSI"})
          end)
        end

      results = Task.await_many(tasks)
      assert Enum.all?(results, &match?({:ok, "clean output"}, &1))
    end
  end

  describe "debug mode" do
    test "handles debug messages without crashing" do
      File.mkdir_p!("test/js/debug_test")

      File.write!("test/js/debug_test/debug_logger.js", """
      // This file outputs debugging information to stdout
      console.log("Debug message: Module loading");
      console.debug("Debug message: Initializing module");

      module.exports = function testFunction(input) {
        console.log(`Debug message: Function called with input: ${input}`);
        console.debug("Debug message: Processing input");

        return `Processed: ${input}`;
      };
      """)

      # With debug_mode disabled, function still works despite debug output
      result = NodeJS.call("debug_test/debug_logger", ["test input"])
      assert {:ok, "Processed: test input"} = result

      # Enable debug_mode to verify it works in that mode too
      original_setting = Application.get_env(:nodejs, :debug_mode)
      Application.put_env(:nodejs, :debug_mode, true)

      # Function still works with debug_mode enabled
      result = NodeJS.call("debug_test/debug_logger", ["test input"])
      assert {:ok, "Processed: test input"} = result

      # Restore original setting
      if is_nil(original_setting) do
        Application.delete_env(:nodejs, :debug_mode)
      else
        Application.put_env(:nodejs, :debug_mode, original_setting)
      end

      # Clean up
      File.rm!("test/js/debug_test/debug_logger.js")
    end
  end
end
