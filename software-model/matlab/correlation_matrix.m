function R=correlation_matrix(X)
    
    % M: Number datapoints per sample
    % N: Number of samples
    [N, M] = size(X);
   
    R = randn([M, M]);
    
    for i=1:N
        d = X(i, :);
        % esperamos a que d este lleno con los nuevos datos
        
        for j=1:M
            matriz_tiene_basura = i == 1;
            
            % Computamos elemento matriz
            if matriz_tiene_basura
                R(j, :) = d * d(j);  
            else
                R(j, :) = d * d(j) + R(j, :);
            end
            
            % si j = 1, indicamos que pueden llegar nuevos datos 
            % (reseteamos el contador de datos de entrada).
        end
    end
  
    % Finalmente dividimos por N
    R = R / N;
end