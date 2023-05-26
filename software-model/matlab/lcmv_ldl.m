function [classificationOutput, W] = lcmv_ldl(T, C, X)
    [N, ~] = size(X);
    
    % Compute corelation matrix

    %R = correlation_matrix(X);
    R = X' * X / N;
    
    t1 = ldl_solve(R, T);    
    t2 = T' * t1;

    t3 = ldl_solve(t2, C);
    
    % Compute the weighting matrix W 
    W = t1 * t3;

    classificationOutput = zeros(N, size(C, 2));

    %Classify each pixel
    for i=1:N
        classificationOutput(i, :) = X(i, :) * W;
    end
end

