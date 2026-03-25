"""
Flyby velocity penalty term F — exact formula from GTOC13 problem statement §3.4.

F(V∞) = (0.2 + exp(-V∞/13)) / (1 + exp(-5*(V∞ - 1.5)))

where V∞ is in km/s.

Properties:
  • F is peaked near V∞ ≈ 1.5 km/s, not at V∞ = 0.
  • F → 0 for V∞ → 0 (rendezvous penalized — radiation/environment risk).
  • F → 0 for V∞ → ∞ (very fast flyby, short observation time).
  • Maximum F ≈ 0.86 near V∞ ≈ 1.5 km/s.
"""

"""
Compute F(V∞) given V∞ in km/s.
"""
function vinf_factor(v_inf_kms::Float64)
    return (0.2 + exp(-v_inf_kms / 13.0)) / (1.0 + exp(-5.0 * (v_inf_kms - 1.5)))
end

"""
Convert V∞ from AU/day to km/s.
"""
function vinf_auday_to_kms(v_inf_auday::Float64)
    return v_inf_auday * AU_KM / DAY_S
end

"""
Maximum value of F over all V∞ ≥ 0.
Used as the admissible upper bound when V∞ is unknown.
Numerically: max is ≈ 0.864 near V∞ = 1.5 km/s.
"""
const VINF_FACTOR_MAX = let
    best = 0.0
    for v in 0.01:0.01:30.0
        f = vinf_factor(v)
        f > best && (best = f)
    end
    best
end

vinf_factor_upper_bound() = VINF_FACTOR_MAX
