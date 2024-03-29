function [AmatEps, ReT] = keEpsAmat(N_xtot, N_ytot, xnodel, ynodel, dxblock, ...
    dyblock, u, v, rhoc, mueffc, mutoldc, mumolc, TKEold, epsold, ydist, dt, jin)
%Set-up eps - Amatrix
    
    ReT = zeros(N_xtot,N_ytot);
    ReT(2:N_xtot-1,2:N_ytot-1) = ((TKEold(2:N_xtot-1,2:N_ytot-1)).^2)./...
        (mumolc.*epsold(2:N_xtot-1,2:N_ytot-1));
    ReT(N_xtot,:) = ReT(N_xtot-1,:); ReT(1,:) = ReT(2,:); 
    ReT(:,1) = ReT(:,2); ReT(:,N_ytot) = ReT(:,N_ytot-1); %change??
    
    Rey = zeros(N_xtot,N_ytot);
    Rey(2:N_xtot-1,2:N_ytot-1) = (TKEold(2:N_xtot-1,2:N_ytot-1).^(1/2)).*...
        ydist(2:N_xtot-1,2:N_ytot-1)./mumolc;
    Rey(N_xtot,:) = Rey(N_xtot-1,:); Rey(1,:) = Rey(2,:); 
    Rey(:,1) = Rey(:,2); Rey(:,N_ytot) = Rey(:,N_ytot-1); %change??
    
    KEpschoice = 1;
    switch KEpschoice
        case 1 %Launder-Sharma
            c_mu = 0.09; c_eps1 = 1.44; c_eps2 = 1.92; 
            sig_k = 1.0; sig_eps = 1.3;
            f1 = 1; f2 = 1 - 0.3.*exp(-(ReT.^2));
    end
    
    mueffceff = mumolc + mutoldc./sig_eps;
    AmatEps = zeros((N_xtot-2)*(N_ytot-2));
    
    for i=1:(N_xtot-2)
        for j=1:(N_ytot-2)
            
            %Calculate Rate of strain tensors Sxy = Syx! Symmetrical!
            Sxx = (u(i+1,j+1) - u(i,j+1))/dxblock(i+1,j+1);
            Syy = (v(i+1,j+1) - v(i+1,j))/dyblock(i+1,j+1);
            Sxy = 1/2*(   ( 1/2*( (u(i+1,j+2)*dyblock(i+1,j+1)+u(i+1,j+1)*dyblock(i+1,j+2))/...
                (dyblock(i+1,j+2)+dyblock(i+1,j+1)) +...
                (u(i,j+2)*dyblock(i+1,j+1)+u(i,j+1)*dyblock(i+1,j+2))/...
                (dyblock(i+1,j+2)+dyblock(i+1,j+1)) ) -...
                1/2*( (u(i+1,j+1)*dyblock(i+1,j)+u(i+1,j)*dyblock(i+1,j+1))/...
                (dyblock(i+1,j+1)+dyblock(i+1,j)) +... 
                (u(i,j+1)*dyblock(i+1,j)+u(i,j)*dyblock(i+1,j+1))/...
                (dyblock(i+1,j+1)+dyblock(i+1,j)) ) )/dyblock(i+1,j+1) +...
                ...
                1/2*( (v(i+2,j+1)*dxblock(i+1,j+1)+v(i+1,j+1)*dxblock(i+2,j+1))/...
                (dxblock(i+2,j+1)+dxblock(i+1,j+1)) +...
                (v(i+2,j)*dxblock(i+1,j+1) + v(i+1,j)*dxblock(i+2,j+1))/...
                (dxblock(i+2,j+1)+dxblock(i+1,j+1)) -...
                (v(i+1,j+1)*dxblock(i,j+1)+v(i,j+1)*dxblock(i+1,j+1))/...
                (dxblock(i+1,j+1)+dxblock(i,j+1)) -...
                (v(i+1,j)*dxblock(i,j+1)+v(i,j)*dxblock(i+1,j+1))/...
                (dxblock(i+1,j+1)+dxblock(i,j+1)) )/dxblock(i+1,j+1)   );
            
            %Production rate of eps!
            P_k = mutoldc(i+1,j+1)/rhoc*( 2*Sxx^2 + 2*Syy^2 + 4*Sxy^2);
            
            %Diagonal terms for eps(i,j) (i+1) (j+1)
            AmatEps(i+(j-1)*(N_xtot-2),i+(j-1)*(N_xtot-2)) = 1/dt + ...
                1/(rhoc*dxblock(i+1,j+1))*(mueffceff(i+2,j+1)*dxblock(i+1,j+1) ...
                + mueffceff(i+1,j+1)*dxblock(i+2,j+1))/...
                (dxblock(i+2,j+1)+dxblock(i+1,j+1))/(xnodel(i+2,j+1)-xnodel(i+1,j+1)) +...
                1/(rhoc*dxblock(i+1,j+1))*(mueffceff(i+1,j+1)*dxblock(i,j+1) ...
                + mueffceff(i,j+1)*dxblock(i+1,j+1))/...
                (dxblock(i+1,j+1)+dxblock(i,j+1))/(xnodel(i+1,j+1)-xnodel(i,j+1)) + ...
                1/(rhoc*dyblock(i+1,j+1))*(mueffceff(i+1,j+2)*dyblock(i+1,j+1) ...
                + mueffceff(i+1,j+1)*dyblock(i+1,j+2))/...
                (dyblock(i+1,j+2)+dyblock(i+1,j+1))/(ynodel(i+1,j+2)-ynodel(i+1,j+1)) + ...
                1/(rhoc*dyblock(i+1,j+1))*(mueffceff(i+1,j+1)*dyblock(i+1,j) ...
                + mueffceff(i+1,j)*dyblock(i+1,j+1))/...
                (dyblock(i+1,j+1)+dyblock(i+1,j))/(ynodel(i+1,j+1)-ynodel(i+1,j)) + ...
                epsold(i+1,j+1)/TKEold(i+1,j+1) - ...
                P_k*c_eps1*f1/TKEold(i+1,j+1) + ...
                c_eps2*f2(i+1,j+1)*epsold(i+1,j+1)/TKEold(i+1,j+1) - ...
                - 1/(xnodel(i+2,j+1)-xnodel(i+1,j+1))*(u(i,j+1)+u(i+1,j+1))/2 ...
                - 1/(ynodel(i+1,j+2)-ynodel(i+1,j+1))*(v(i+1,j+1)+v(i+1,j))/2;

            %Implicit BC: eps(N_xtot,:) = eps(N_xtot-1,:) %checked!
            if(i==(N_xtot-2)) 
                AmatEps(i+(j-1)*(N_xtot-2),i+(j-1)*(N_xtot-2)) = ...
                    AmatEps(i+(j-1)*(N_xtot-2),i+(j-1)*(N_xtot-2)) + ...
                    (1/(xnodel(i+2,j+1)-xnodel(i+1,j+1))*(u(i,j+1)+u(i+1,j+1))/2 - ...
                    1/(rhoc*dxblock(i+1,j+1))*(mueffceff(i+2,j+1)*dxblock(i+1,j+1) ...
                    + mueffceff(i+1,j+1)*dxblock(i+2,j+1))/...
                    (dxblock(i+2,j+1)+dxblock(i+1,j+1))/(xnodel(i+2,j+1)-xnodel(i+1,j+1)));
            end

            %Implicit BC: eps(1,(jin+1):N_ytot) = - eps(1,(jin+1):N_ytot) %checked!
            if(i==1 && j>=jin)
                AmatEps(i+(j-1)*(N_xtot-2),i+(j-1)*(N_xtot-2)) = ...
                    AmatEps(i+(j-1)*(N_xtot-2),i+(j-1)*(N_xtot-2)) - ...
                    ( - 1/(rhoc*dxblock(i+1,j+1))*(mueffceff(i+1,j+1)*dxblock(i,j+1) ...
                    + mueffceff(i,j+1)*dxblock(i+1,j+1))/...
                    (dxblock(i+1,j+1)+dxblock(i,j+1))/(xnodel(i+1,j+1)-xnodel(i,j+1)) );
            end
            
            %Implicit BC: eps(1,1:jin) = epsinlet in Source Term!
            
            %Implicit BC: eps(:,1) = eps(:,2); %checked!
            if(j == 1)
                AmatEps(i+(j-1)*(N_xtot-2),i+(j-1)*(N_xtot-2)) = ...
                    AmatEps(i+(j-1)*(N_xtot-2),i+(j-1)*(N_xtot-2)) +...
                    ( - 1/(rhoc*dyblock(i+1,j+1))*(mueffceff(i+1,j+1)*...
                    dyblock(i+1,j)+mueffceff(i+1,j)*dyblock(i+1,j+1))/...
                    (dyblock(i+1,j+1)+dyblock(i+1,j))/(ynodel(i+1,j+1)-ynodel(i+1,j)) );
            end
            
            %Implicit BC: eps(:,N_ytot) = - eps(:,N_ytot-1) %checked!
            if(j==(N_ytot-2))
                AmatEps(i+(j-1)*(N_xtot-2),i+(j-1)*(N_xtot-2)) = ...
                    AmatEps(i+(j-1)*(N_xtot-2),i+(j-1)*(N_xtot-2)) - ...
                    (1/(ynodel(i+1,j+2)-ynodel(i+1,j+1))*(v(i+1,j+1)+v(i+1,j))/2 - ...
                    1/(rhoc*dyblock(i+1,j+1))*(mueffceff(i+1,j+2)*...
                    dyblock(i+1,j+1) + mueffceff(i+1,j+1)*dyblock(i+1,j+2))/...
                    (dyblock(i+1,j+2)+dyblock(i+1,j+1))/(ynodel(i+1,j+2)-ynodel(i+1,j+1)));
            end
            
        end
    end
    for i=1:(N_xtot-3)
        for j =1:(N_ytot-2)
            %Term for eps(i+1,j) (i+1) (j+1) %checked!
            AmatEps(i+(j-1)*(N_xtot-2), i+(j-1)*(N_xtot-2)+1) = ...
                1/(xnodel(i+2,j+1)-xnodel(i+1,j+1))*(u(i,j+1)+u(i+1,j+1))/2 - ...
                1/(rhoc*dxblock(i+1,j+1))*(mueffceff(i+2,j+1)*dxblock(i+1,j+1) ...
                + mueffceff(i+1,j+1)*dxblock(i+2,j+1))/...
                (dxblock(i+2,j+1)+dxblock(i+1,j+1))/(xnodel(i+2,j+1)-xnodel(i+1,j+1));
            %Term for eps(i-1,j) (i+2) (j+1) %checked!
            AmatEps(i+(j-1)*(N_xtot-2)+1, i+(j-1)*(N_xtot-2)) =  ...
                - 1/(rhoc*dxblock(i+2,j+1))*(mueffceff(i+2,j+1)*dxblock(i+1,j+1) ...
                + mueffceff(i+1,j+1)*dxblock(i+2,j+1))/...
                (dxblock(i+2,j+1)+dxblock(i+1,j+1))/(xnodel(i+2,j+1)-xnodel(i+1,j+1));
        end
    end
    for i=1:(N_xtot-2)
        for j=1:(N_ytot-3)
            %Term for eps(i,j+1) (i+1) (j+1) %checked!
            AmatEps(i+(j-1)*(N_xtot-2), i+j*(N_xtot-2)) = ...
                1/(ynodel(i+1,j+2)-ynodel(i+1,j+1))*(v(i+1,j+1)+v(i+1,j))/2 - ...
                1/(rhoc*dyblock(i+1,j+1))*(mueffceff(i+1,j+2)*dyblock(i+1,j+1) ...
                + mueffceff(i+1,j+1)*dyblock(i+1,j+2))/...
                (dyblock(i+1,j+2)+dyblock(i+1,j+1))/(ynodel(i+1,j+2)-ynodel(i+1,j+1));
            %Term for eps(i,j-1) (i+1) (j+2) %checked!
            AmatEps(i+j*(N_xtot-2), i+(j-1)*(N_xtot-2)) = ...
                - 1/(rhoc*dyblock(i+1,j+2))*(mueffceff(i+1,j+2)*dyblock(i+1,j+1) ...
                + mueffceff(i+1,j+1)*dyblock(i+1,j+2))/...
                (dyblock(i+1,j+2)+dyblock(i+1,j+1))/(ynodel(i+1,j+2)-ynodel(i+1,j+1));
        end
    end
end