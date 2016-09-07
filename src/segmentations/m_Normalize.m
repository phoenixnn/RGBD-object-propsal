% 20130604  Zhuo Deng Temple University
% normalize an input matrix of which values fall in [0,1]
% currently Input is a 1D or 2D matrix

function  Mat_norm = m_Normalize(Matrix)
    M = max(Matrix(:));
    N = min(Matrix(:));
    diff = double(M-N);
    if diff == 0
        diff = diff + eps;
    end
    Mat_norm = (Matrix - N) / diff;
end