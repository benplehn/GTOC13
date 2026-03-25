"""
Load precomputed ephemeris data.
"""

function load_ephemerides(path::String=package_path("data", "processed", "ephemerides.jld2"))
    if isfile(path)
        data = JLD2.load(path)
        if haskey(data, "segments")
            return data["segments"]
        end
        return data
    end

    if isdir(path)
        files = sort(filter(file -> endswith(file, ".jld2"), readdir(path; join=true)))
        datasets = Dict{String, Any}()
        for file in files
            datasets[basename(file)] = JLD2.load(file)
        end
        return datasets
    end

    error("Ephemeris path not found: $path")
end
