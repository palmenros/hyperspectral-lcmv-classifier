function M=matrix_divide(A, d)
    M = A;
    [~, n] = size(A);
    for k=1:n
        M(:, k) = M(:, k) ./ d';
    end
end