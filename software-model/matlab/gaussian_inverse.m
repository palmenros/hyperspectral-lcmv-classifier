function [I] = gaussian_inverse(A)
    n = size(A, 1);
    I = eye(n);

    % Indexing array to store row permutations without permuting
    % the matrix itself
    row = 1:n;
    %eps = 1e-5;

    % Forward elimination to build an upper triangular matrix
    for i=1:n
        % Find pivot

        if A(row(i), i) == 0
        %if abs(A(row(i), i)) < eps
            for j=(i+1):n
                if A(row(j), i) ~= 0
                %if abs(A(row(j), i)) > eps
                    % Parallely swap
                    % row[i], row[j] = row[j], row[i]

                    tmp = row(i);
                    row(i) = row(j);
                    row(j) = tmp;
                end
            end
        end
        
        % If we could not find a valid pivot, matrix is singular
        if A(row(i), i) == 0
            error('Matrix is singular');
        end
        
        % Actually row reduce
        for j=(i+1):n
            factor = A(row(j), i) / A(row(i), i);
            
            % The following two row assignments are done in parallel
            A(row(j), :) = A(row(j), :) - A(row(i), :) * factor;
            I(row(j), :) = I(row(j), :) - I(row(i), :) * factor;
        end
        
    end

    % Backward elimination to build a diagonal matrix
    for i=n:-1:2
        for j=(i-1):-1:1
            factor = A(row(j), i) / A(row(i), i);

            % A(row(j), :) = A(row(j), :) - A(row(i), :) * factor;
            
            % The matrix A doesn't need to be updated, only matrix I
            I(row(j), :) = I(row(j), :) - I(row(i), :) * factor;
        end
    end

    % Last division to build an identity matrix
    for i=1:n
        factor = 1/A(row(i), i);

        I(row(i), :) = I(row(i), :) * factor;
    end


    % Not needed on hardware, finally reorder all rows
    I = I(row, :);
end

