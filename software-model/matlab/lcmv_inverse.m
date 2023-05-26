function [classificationOutput] = lcmv_inverse(T, C, X)
    [N, ~] = size(X);
    
    % Compute corelation matrix

    % Multiply first by 1/sqrt(N) in order to have a better range
    R = (1/sqrt(N) * X') * (1/sqrt(N) * X);
    
    % Compute inverse of R
    R_inv = gaussian_inverse(R);
    
    t1 = R_inv * T;
    t2 = T' * t1;

    inv_t2 = gaussian_inverse(t2);
    t3 = inv_t2 * C;
    
    % Compute the weighting matrix W 
    W = t1 * t3;

    classificationOutput = zeros(N, size(C, 2));

    %Classify each pixel
    for i=1:N
        classificationOutput(i, :) = X(i, :) * W;
    end
end

