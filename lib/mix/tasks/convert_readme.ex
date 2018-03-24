defmodule Mix.Tasks.ConvertReadme do
  use Mix.Task

  @shortdoc "Puts the moduledoc into the README.md"
  def run(_) do
    {_line, text} = Code.get_docs(Snapshot, :moduledoc)

    File.cwd!()
    |> Path.join("README.md")
    |> File.write!("# Snapshot\n\n#{text}")
  end
end
