defmodule Snapshot do
  @moduledoc """
  # Snapshot

  Snapshot is a library that makes testing code that has side-effects or is really slow for other reasons
  as fast and relyable as your other tests, without writing a single line of code.

  ## Why would you want to use Snapshot:

  - Slow tests (for instance testing a client that does a network requests), turn tests that take
    seconds and make them run in microseconds.

  - Reliable results (for instance testing a client that does
    network requests but you don't want to break tests if the target website changes, or a network request times out)

  - Having tests work in an environment that does not have access to the resources. For instance
    you would like to test a client that reaches out to AWS S3 in a continuous integration environment
    that does not have the AWS authentication keys setup in the test environment.

  - Not have slow tests behind a `tag` (and always forget to run them), but run them everytime.

  ## How to add this

  It's good practice to seperate out the client with side effects in a seperate module. Say we have
  a HTTP client that looks like this:

    defmodule Client
      def get(url) do
        ...
      end
    end

  To add Snapshot to this module and make tests of another Module that uses Client very fast we
  only need to do this:

    defmodule Client
      use Snapshot

      def get(url) do
        ...
      end
    end

  Now our tests will create and use snapshots when the get function is used. Snapshot will do
  this for all public (`def`) functions in the module. The default folder where snapshots are
  saved is in `<your project>/test/snapshots` (but this can be configured by settting the `dir`
  option in the configuration:

    config :snapshot, dir: Path.join([__DIR__, "..", "test", "snapshots"])

  If you'd like to remove the cached result just remove this folder (or specific files).

  If you like to make sure the tests will always use the snapshots and never actually run the (network) code,
  you can add the following afther the snapshots have been created. Now we get an error if a URL is requested
  where we do not have a snapshot from yet.

    defmodule Client
      use Snapshot, locked: true

      def get(url) do
        ...
      end
    end

  The best thing about this? Due to the macro system, in production or development the snapshot
  code is completely omitted. This means that adding snapshot has zero performance impact for
  code that is not test-code.


  ## Installation

  The package can be installed
  by adding `snapshot` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:snapshot, "~> 0.1.0"}
    ]
  end
  ```
  """
  import Kernel, except: [def: 2]

  defmacro __using__(opts) do
    quote do
      import Kernel, except: [def: 2]
      import Snapshot

      @__snapshot_locked unquote(opts[:locked])

      defp snapshot__hash(binary), do: :crypto.hash(:md5, binary)

      defp snapshot__term_to_hash({m, f, a}) do
        "#{f}_" <> ({m, f, a} |> :erlang.term_to_binary() |> snapshot__hash() |> Base.encode16())
      end

      defp snapshot__dir(module),
        do:
          Path.join(
            Application.get_env(:snapshot, :dir) || Path.join([File.cwd!(), "test", "snapshots"]),
            Macro.underscore(module)
          )
    end
  end

  defp def_snapshot(call, expr, caller) do
    {f, c, a} = call
    module = caller.module
    [do: do_block] = expr

    quote do
      Kernel.def unquote({:"snapshot__original_#{f}", c, a}) do
        unquote(do_block)
      end

      Kernel.def unquote(call) do
        snapshot_path =
          Path.join([
            snapshot__dir(unquote(module)),
            snapshot__term_to_hash({unquote(module), unquote(f), unquote(a)})
          ])

        case File.read(snapshot_path) do
          {:ok, binary} ->
            :erlang.binary_to_term(binary)

          {:error, _} ->
            if @__snapshot_locked do
              raise "No snapshot found for: #{unquote(module)}.#{unquote(f)} called with the following arguments: \n #{
                      inspect(unquote(a))
                    }"
            else
              result = apply(unquote(module), :"snapshot__original_#{unquote(f)}", unquote(a))
              File.mkdir_p(snapshot__dir(unquote(module)))
              File.write!(snapshot_path, :erlang.term_to_binary(result))
              result
            end
        end
      end
    end
  end

  defmacro def(call, expr) do
    case Mix.env() do
      :test ->
        def_snapshot(call, expr, __CALLER__)

      _ ->
        quote do
          Kernel.def(unquote(call), unquote(expr))
        end
    end
  end
end
