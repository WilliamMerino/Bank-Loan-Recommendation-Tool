import Pkg

# Activate this repo as the project and ensure deps are present
Pkg.activate(@__DIR__)
try
    Pkg.instantiate()
catch
    # Non-fatal: continue; main.jl will also try to bootstrap core deps
end

# Load and run the CLI
include(joinpath(@__DIR__, "src", "main.jl"))
if isdefined(Main, :main)
    Main.main()
end
