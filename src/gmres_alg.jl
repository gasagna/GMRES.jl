export gmres!

# Data structure for convergence analysis.
mutable struct ConvergenceResults
    hist::Vector{Float64}
    status::Symbol
end
ConvergenceResults() = ConvergenceResults(Float64[1.0], :unknown)

Base.push!(convres::ConvergenceResults, r::Real) = push!(convres.hist, r)

"""
    gmres!(A, b; [tol=1e-6], [maxiter=10])

Solve `Ax=b` using the GMRES method. 
"""
function gmres!(A, b; tol=1e-6, maxiter=10)
    # store norm of b
    bnorm = norm(b)

    # store trace
    convres = ConvergenceResults()

    # set up arnoldi iteration
    arn = ArnoldiIteration(A, b)

    # right hand side
    g = Float64[bnorm]
    
    # run for maxiter iterations
    for i = 1:maxiter

        # run arnoldi step
        Q, H = arnoldi!(arn)

        # grow right hand side
        push!(g, 0.0)

        # solve least squares problem
        y = arn.H\g 

        # check convergence
        rnorm = norm(H*y - g)

        # store trace
        push!(convres, rnorm/bnorm)

        if rnorm < tol
            # update convergence status
            convres.status = :converged
            return lincomb!(b, Q, y), convres
        end
    end

    # update convergence status
    convres.status = :maxiterreached
    return b, convres
end

"""
    lincomb!(out, Q, y)

Compute linear combination of first `n` elements of `Q` using weights in the 
vector `y` of length `n`, writing the result in `out`. With this function, the
solution in the full space is recovered from its projection `y` on the Krylov
subspace basis given by the orthogonal columns of `Q`.
"""
function lincomb!(out::X, Q::Vector{X}, y::Vector{<:Real}) where X
    length(Q) == length(y)+1 || error("length(Q) must be length(y)+1")
    out .= Q[1].*y[1]
    for i = 2:length(y)
        out .+= Q[i].*y[i]
    end
    return out
end