% Solves X such that A * X = B using the LDL factor of A
function [X] = ldl_solve(A, B)
    % L*D*L' == A
    [L, D] = my_ldl(A);
    n = size(A, 1);
        
    % We want to solve A*X=B <=> L*D*L' * X = B
    m=size(B, 2);

    W = zeros(n, m);
    
    % We start solving L*W = B

    W(1, :) = B(1, :);
    
    % TODO: Study where to parallelize for hardware implementation
    for i=2:n
       for k=1:m
            %W(i, k) = B(i, k) - L(i, 1:i-1)*W(1:i-1, k);
            % TODO: For loop only done for Fixed-Point toolchain converter, 
            %       use as reference the above formula.
    
            W(i, k) = B(i, k);
            for l=1:i-1
                W(i, k) = W(i, k) - L(i, l) * W(l, k);
            end
       end
    end
    
    % Now we solve D*W2 = W
    W2 = zeros(n, m);

    for k=1:m
        W2(:, k) = W(:, k) ./ diag(D);
    end

    % Finally we solve L'*X = W2
    X = zeros(n, m);
    
    X(n, :) = W2(n, :);
    for i=(n-1):-1:1
       for k=1:m
            %X(i, k) = W2(i, k) - X((i+1):n, k)' * L((i+1):n, i);
            % TODO: For loop only done for Fixed-Point toolchain converter, 
            %       use as reference the above formula.
            
            X(i, k) =  W2(i, k);
            for l = i+1:n
                X(i, k) = X(i, k) - X(l, k) * L(l, i);
            end
       end
    end
end

function [L, D] = my_ldl(A)
    n = length(A);
    v = zeros(n,1);
    d = zeros(n, 1);
    
    for j = 1:n
        v(1:j-1) = A(j, 1:j-1) .* d(1:j-1)';
        
        %d(j) = A(j, j) - A(j, 1:j - 1) * v(1:j - 1);
        
        % TODO: For loop only done for Fixed-Point toolchain converter, 
        %       use as reference the above formula.
        d(j) = A(j, j);
        for k=1:j-1
            d(j) = d(j) - A(j, k) * v(k);
        end


        for k=j+1:n
           % A(k, j) = (A(k,j) - A(k, 1:j - 1) * v(1:j - 1)) / d(j);
           
           % TODO: For loop only done for Fixed-Point toolchain converter, 
           %       use as reference the above formula.
           
           for l=1:j-1
            A(k, j) = A(k, j) - A(k, l) * v(l);
           end
           A(k, j) = A(k, j) / d(j);

        end
    end
    L = tril(A,-1)+eye(n);
    D = diag(d);
end
