"""
Provides unofficial implementations (in the form of `ODESystem` and 
`ODEFunction` instances) of a polynomial approximation for longitudinal 
aircraft dynamics. Specifically, these models approximate NASA's 
Generic Transport Model – a radio-controlled, sub-scale model aircraft which 
is used flight control research. These publicly available equations were published by 
[Chakraborty et al](https://www.sciencedirect.com/science/article/abs/pii/S0967066110002595).

# Extended help

## License

$(LICENSE)

## Exports

$(EXPORTS)

## Imports

$(IMPORTS)
"""
module PolynomialGTM

using Memoize
using Symbolics
using LinearAlgebra
using ModelingToolkit 
using DocStringExtensions

@template (FUNCTIONS, METHODS, MACROS) =
    """
    $(SIGNATURES)

    $(DOCSTRING)
    """

@template (TYPES, CONSTANTS) =
    """
    $(TYPEDEF)

    $(DOCSTRING)
    """

export GTM, GTMFunction

"""
NASA's Generic Transport Model can be approximated 
(near select flight conditions) as a polynomial model.
Here, `GTM` is a `ModelingToolkit.ODESystem` which
provides publicly available polynomial approximations
for GTM longitudinal flight dynamics.

# Extended Help

## Initial Conditions

The default initial conditions are one trim condition.
Two trim conditions for these polynomial-approximated
dynamics are shown below.

```julia
trim₁ = [[29.6, deg2rad(9), 0.0, deg2rad(9)],   [deg2rad(0.68), 12.7]]  
trim₂ = [[25.0, deg2rad(18), 0.0, deg2rad(18)], [deg2rad(-7.2), 59]]
```

## Usage

```julia
model = GTM()
```
## References:

- [Chakraborty et al](https://www.sciencedirect.com/science/article/abs/pii/S0967066110002595)
- [Joe Carpinelli](https://github.com/cadojo/Replicated-ROA-Analysis)
"""
@memoize function GTM(; stm=false, structural_simplify=true, name=:GTM)
        
    # First, let's define the necessary parameters 
    # and variables for modeling the longitudinal
    # dynamics for NASA's Generic Transport Model

    @parameters t δₑ δₜ
    @variables V(t) α(t) q(t) θ(t) 
    δ = Differential(t)
    x = [V, α, q, θ]
    p = [δₑ, δₜ]

    # Great! Now, we'll need to hard-code in the polynomial 
    # approximations the longitudinal dynamics.

    eqs = [

        # Damn Unicode and its variable character font width!!!

        δ(V) ~  1.233e-8*V^4*q^2 + 4.853e-9*α^3*δₜ^3 	  	+ 
                3.705e-5*V^3*α*q - 2.184e-6*V^3*q^2 		+ 
                2.203e-2*V^2*α^3 - 2.836e-6*α^3*δₜ^2 	  	+ 
                3.885e-7*α^2*δₜ^3 - 1.069e-6*V^3*q 	  		- 
                4.517e-2*V^2*α^2 - 2.140e-3*V^2*α*δₑ 		- 
                3.282e-3*V^2*α*q - 8.901e-4*V^2*δₑ^2 		+ 
                9.677e-5*V^2*q^2 - 2.037e-4*α^3*δₜ 	  	 	 -
                2.270e-4*α^2*δₜ^2 - 2.912e-8*α*δₜ^3 	     +	 
                1.591e-3*V^2*α - 4.077e-4*V^2*δₑ 		  	+
                9.475e-5*V^2*q - 1.637*α^3 				  	- 
                1.631e-2*α^2*δₜ + 4.903*α^2*θ 		  		- 
                4.903*α*θ^2 + 1.702e-5*α*δₜ^2 		  		- 
                7.771e-7*δₜ^3 + 1.634*θ^3 - 4.319e-4*V^2    - 
                2.142e-1*α^2 + 1.222e-3*α*δₜ 			  	+ 
                4.541e-4*δₜ^2 + 9.823*α + 3.261e-2*δₜ 	    - 
                9.807*θ + 4.282e-1,
        δ(α) ~ -3.709e-11*V^5*q^2 + 6.869e-11*V*α^3*δₜ^3 	+ 
                7.957e-10*V^4*α*q + 9.860e-9*V^4*q^2 		+ 
                1.694e-5*V^3*α^3 - 4.015e-8*V*α^3*δₜ^2 		 - 
                7.722e-12*V*α^2*δₜ^3 - 6.086e-9*α^3*δₜ^3 	 - 
                2.013e-8*V^4*q - 5.180e-5*V^3*α^2 			- 
                2.720e-6*V^3*α*δₑ - 1.410e-7*V^3*α*q 		+ 
                7.352e-7*V^3*δₑ^2 - 8.736e-7*V^3*q^2 		- 
                1.501e-3*V^2*α^3 - 2.883e-6*V*α^3*δₜ 		+ 
                4.513e-9*V*α^2*δₜ^2 - 4.121e-10*V*α*δₜ^3 	+ 
                3.557e-6*α^3*δₜ^2 + 6.841e-10*α^2*δₜ^3 		+ 
                4.151e-5*V^3*α + 3.648e-6*V^3*δₑ 		    + 
                3.566e-6*V^3*q + 6.246e-6*V^2*α*q 			+ 
                4.589e-3*V^2*α^2 + 2.410e-74*V^2*α*δₑ 		- 
                6.514e-5*V^2*δₑ^2 + 2.580e-5*V^2*q^2 		- 
                3.787e-5*V*α^3 + 3.241e-7*V*α^2*δₜ 			+ 
                2.409e-7*V*α*δₜ^2 + 1.544e-11*V*δₜ^3 		+ 
                2.554e-4*α^3*δₜ - 3.998e-7*α^2*δₜ^2 		+ 
                3.651e-8*α*δₜ^3 + 4.716e-7*V^3 				- 
                3.677e-3*V^2*α - 3.231e-4*V^2*δₑ 			- 
                1.579e-4*V^2*q + 2.605e-3*V*α^2 			+ 
                1.730e-5*V*α*δₜ - 5.201e-3*V*α*θ 			-
                9.026e-9*V*δₜ^2 + 2.601e-3*V*θ^2 			+ 
                3.355e-3*α^3 - 2.872e-5*α^2*δₜ 				- 
                2.134e-5*α*δₜ^2 - 1.368e-9*δₜ^3 		    - 
                4.178e-5*V^2 + 2.272e-4*V*α 				- 
                6.483e-7*V*δₜ - 2.308e-1*α^2 				- 
                1.532e-3*α*δₜ + 4.608e-1*α*θ - 2.304e-1*θ^2 + 
                7.997e-7*δₜ^2 - 5.210e-3*V - 2.013e-2*α 	+ 
                5.744e-5*δₜ + q + 4.616e-1,
        δ(q) ~ -6.573e-9*V^5*q^3 + 1.747e-6*V^4*q^3 	    - 
                1.548e-4*V^3*q^3 - 3.569e-3*V^2*α^3 	    + 
                4.571e-3*V^2*q^3 + 4.953e-5*V^3*q 		    + 
                9.596e-3*V^2*α^2 + 2.049e-2*V^2*α*δₑ 	    - 
                2.431e-2*V^2*α - 3.063e-2*V^2*δₑ 		    - 
                4.388e-3*V^2*q - 2.594e-7*δₜ^3 			    + 
                2.461e-3*V^2 + 1.516e-4*δₜ^2 + 1.089e-2*δₜ 	 + 
                1.430e-1,
        δ(θ) ~ q
    ]

    # Let's set some default values, so we can plug this system directly 
    # into `ODEProblem` and perform quick analysis. Note that what we're 
    # doing here is setting one equilibrium position as a default 
    # initial condition if no arguments are provided to `ODEProblem`!
    defaults = Dict(
        V  => 29.6, 
        α  => deg2rad(9), 
        q  => 0.0, 
        θ  => deg2rad(0), 
        δₑ => deg2rad(0.68), 
        δₜ => 12.7
    )

    # If state transition matrix dynamics are enabled, append 
    # the dynamics to our equations of motion, append the 
    # state variables to our state vector, and append default
    # values (the identity matrix) to the defaults field!
    if stm
        @variables Φ[1:4,1:4](t)
        Φ = Symbolics.scalarize(Φ)
        A = Symbolics.jacobian(map(el -> el.rhs, eqs), x)
        
        LHS = map(δ, Φ)
        RHS = map(simplify, A * Φ)
    
        eqs = vcat(eqs, [LHS[i] ~ RHS[i] for i in 1:length(LHS)])
    
        for ϕ in vec(Φ)
            push!(x, ϕ)
        end

        for (ϕ, i) in zip(vec(Φ), vec(Matrix(I(4))))
            defaults[ϕ] = i
        end    
    end

    # Model name
    if string(name) == "GTM" && stm 
        modelname = Symbol("GTMWithSTM")
    else
        modelname = name
    end

    # Make the model and return
    model = ODESystem(eqs, t, x, p; defaults=defaults, name=Symbol(modelname))
    return structural_simplify ? ModelingToolkit.structural_simplify(model) : model
end

"""
Returns a `DifferentialEquations`-compatible `ODEFunction` for GTM dynamics.
The `stm`, `structural_simplify`, and `name` keyword arguments are passed
to `GTM`. All other keyword arguments are passed directly to `ODEFunction`.

# Extended Help

## Usage

Note that this `ODEFunction` output has several methods, including an in-place 
method! Function signatures follow `ModelingToolkit` and `DifferentialEquations`
conventions. 

```julia
f = GTMFunction()
let u = randn(4), p = randn(2), t = rand()
    f(u,p,t)
end
```
"""
@memoize function GTMFunction(; stm=false, structural_simplify=true, name=:GTM, kwargs...)
    defaults = (; jac = true)
    options  = merge(defaults, kwargs)
    
    model = GTM(; stm=stm, structural_simplify=structural_simplify, name=name)
    return ODEFunction(model; options...)
end


end # module
