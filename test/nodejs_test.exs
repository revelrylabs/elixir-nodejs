defmodule NodeJS.Test do
  use ExUnit.Case
  doctest NodeJS

  setup_all do
    path =
      __ENV__.file
      |> Path.dirname()
      |> Path.join("js")

    NodeJS.start_link(path: path)

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
      assert js_error_message(msg) === "TypeError: Converting circular structure to JSON"
    end
  end

  describe "calling things that are not functions: " do
    test "module does not exist" do
      assert {:error, msg} = NodeJS.call("idontexist")
      assert js_error_message(msg) === "Error: Cannot find module 'idontexist'"
    end

    test "function does not exist" do
      assert {:error, msg} = NodeJS.call({"keyed-functions", :idontexist})
      assert js_error_message(msg) === "TypeError: fn is not a function"
    end

    test "object does not exist" do
      assert {:error, msg} = NodeJS.call({"keyed-functions", :idontexist, :foo})
      assert js_error_message(msg) === "TypeError: Cannot read property 'foo' of undefined"
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
  end
end
