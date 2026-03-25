const STATE_ATOL = 1e-10
const STATE_RTOL = 1e-10
const VECTOR_ATOL = 1e-10
const ANGLE_ATOL = 1e-12

normalize_csv_line(line::AbstractString) = replace(chomp(line), '\r' => "")
csv_fields(line::AbstractString) = strip.(split(normalize_csv_line(line), ','))

function state_approx_equal(a::CartesianState, b::CartesianState;
                            atol::Float64=STATE_ATOL,
                            rtol::Float64=STATE_RTOL)
    return isapprox(a.t, b.t; atol=atol, rtol=0.0) &&
           isapprox(a.r, b.r; atol=atol, rtol=rtol) &&
           isapprox(a.v, b.v; atol=atol, rtol=rtol)
end

function error_message(f::Function)
    try
        f()
    catch err
        return sprint(showerror, err)
    end
    return nothing
end
