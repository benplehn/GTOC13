"""
Reference frame utilities.
"""

"""
Heliocentric direction unit vector from spacecraft position.
"""
function heliocentric_direction(r::SVector{3,Float64})
    return r / norm(r)
end

"""
Ecliptic longitude and latitude [rad] from a position vector.
"""
function ecliptic_lon_lat(r::SVector{3,Float64})
    r_hat = r / norm(r)
    lat = asin(clamp(r_hat[3], -1.0, 1.0))
    lon = atan(r_hat[2], r_hat[1])
    return lon, lat
end
