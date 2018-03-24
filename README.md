# Snapshot

Snapshot is a library that makes testing code that has side-effects or is really slow for other reasons
as fast and relyable as your other tests, without writing a single line of code.

## Why would you want to use Snapshot:

* Slow tests (for instance testing a client that does a network requests), turn tests that take
  seconds and make them run in microseconds.

* Reliable results (for instance testing a client that does
  network requests but you don't want to break tests if the target website changes, or a network request times out)

* Having tests work in an environment that does not have access to the resources. For instance
  you would like to test a client that reaches out to AWS S3 in a continuous integration environment
  that does not have the AWS authentication keys setup in the test environment.

* Not have slow tests behind a `tag` (and always forget to run them), but run them everytime.

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
