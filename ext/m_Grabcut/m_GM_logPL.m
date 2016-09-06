function [ LogPL ] = m_GM_logPL( x, mu, detcovar, icovar)
% compute negative gaussian log likelihood
% f(x) = {det(cov)}^(-0.5) * exp{-0.5 * (x-mu)' * inv(cov) * (x-mu)}
% - log{f(x)} = 0.5 * log{det(cov)} + 0.5 * (x-mu)' * inv(cov) * (x-mu)

% Inputs:
% x : N x d matrix  each row is one example
% mu: mean vector dx1
% covar: covariance matrix dxd

% Outputs:
% LogPL : N x 1

N = size(x, 1);
LogPL = 0.5 * log (detcovar) + 0.5 * sum ((x- repmat(mu',N, 1)) * icovar ...
        .* (x - repmat(mu',N,1)), 2);


end

