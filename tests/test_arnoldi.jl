@testset "symmetric                              " begin
    # construct random symmetric matrix and rhs
    Random.seed!(0)
    A = randn(400, 400)
    A = A + A'
    b = randn(400)

    # create iterator
    arn = ArnoldiIteration(A, b)

    # the square part must be symmetric to machine accuracy
    for i = 1:6
        Q, H = arnoldi!(arn)
        @test issymmetric(round.(H[1:i, 1:i]; digits=13))
    end
end

@testset "definition                             " begin
    # construct random matrix and rhs
    A = randn(4, 4)
    b = randn(4)

    # create iterator
    arn = ArnoldiIteration(A, b)
    
    Q, H = arnoldi!(arn)
    @test Q[1] ≈ b/norm(b)

    Q, H = arnoldi!(arn)
    v = A*Q[1] - ((A*Q[1])⋅Q[1])*Q[1]
    @test Q[2] ≈ v/norm(v)

    Q, H = arnoldi!(arn)
    v = A*Q[2] - (A*Q[2]⋅Q[2])*Q[2] - ((A*Q[2])⋅Q[1])*Q[1]
    @test Q[3] ≈ v/norm(v)

    Q, H = arnoldi!(arn)
    v = A*Q[3] - (A*Q[3]⋅Q[3])*Q[3] - ((A*Q[3])⋅Q[2])*Q[2] - ((A*Q[3])⋅Q[1])*Q[1]
    @test Q[4] ≈ v/norm(v)
end

@testset "H matrix                               " begin
    # construct random matrix and rhs
    for N = 4:10
        A = randn(N, N)
        b = randn(N)

        # create iterator
        arn = ArnoldiIteration(A, b)
        
        Q, H = arnoldi!(arn)
        @test H[1, 1] ≈ A*Q[1]⋅Q[1]
        @test H[2, 1] ≈ norm(A*Q[1] - (A*Q[1]⋅Q[1])*Q[1])

        # run till end
        for i = 1:N
            Q, H = arnoldi!(arn)
        end

        # get Q into a matrix
        Qm = hcat([qi for qi in Q[1:N]]...)
        
        @test norm(A*Qm - Qm*H[1:N, 1:N]) < 4e-13
    end
end

@testset "orthogonality                          " begin
    # construct random matrix and rhs
    Random.seed!(0)
    m = 10
    A = 2*Matrix{Float64}(I, m, m) + 0.5*randn(m, m)/sqrt(m)
    b = randn(m)

    # create iterator
    arn = ArnoldiIteration(A, b)
    
    # add m-1 vectors
    Q, H = arnoldi!(arn)
    for i = 1:m-2
        Q, H = arnoldi!(arn)
    end

    @test norm([qi⋅qj for qi in Q, qj in Q] - Matrix{Float64}(I, m, m)) < 2.0e-15
end