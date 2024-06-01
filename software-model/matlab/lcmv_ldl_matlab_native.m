function W=lcmv_ldl_matlab_native(T, C, X) %#codegen
    [N, ~] = size(X);

    % R = correlation_matrix(X);

    % TIMING_0
    R = X' * X;

    % TIMING_1
    R = R / N;

    % TIMING_2

    % Alternative: t1 = R \ T;
    %t1 = R \ T;
    t1 = native_ldl_solve(R, T);

    % TIMING_3

    t2 = T' * t1;

    % TIMING_4

    % Alternative: t3 = t2 \ C;
    %t3 = t2 \ C;
    t3 = native_ldl_solve(t2, C);

    % TIMING_5

    % Compute the weighting matrix W
    W = t1 * t3;

    % TIMING_6
end

function X=native_ldl_solve(A, B) %#codegen
    [L, D] = ldl(A);
    W = L \ B;
    W = D \ W;
    X = L' \ W;
end
