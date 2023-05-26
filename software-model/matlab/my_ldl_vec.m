
function [L, D] = my_ldl_vec(A)
    n = length(A);
    v = zeros(n,1);
    d = zeros(n, 1);
    
    for j = 1:n
        r = A(j,:);
        v = r .* d';
        d(j) = A(j, j) - r( 1:j-1) * v(1:j - 1)';

        for k=j+1:n
           r = A(k, :);
           A(k, j) = (A(k,j) - r(1:j - 1) * v(1:j - 1)') / d(j);
        end
    end
    L = tril(A,-1)+eye(n);
    D = diag(d);
end