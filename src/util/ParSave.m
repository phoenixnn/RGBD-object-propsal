function ParSave(fname, varargin)
% zhuo deng
% temple university

% save within the parfor loop
% e.g.,  m_parsave('./filename.mat', x);
%        m_parsave('./filename.mat', x, y, z);

%fprintf('number of arguments is %d\n ', nargin);

if nargin < 2
    assert(false, 'not enough parameters\n');
else 
   for i = 2 : nargin
       var_name = inputname(i);
       eval([var_name sprintf('= varargin{%d};', i-1)]);
       try
            save(fname,var_name,'-append');
       catch
            save(fname,var_name, '-v7.3');
       end
   end
end

end


% function helper(fname, data)
% 
% var_name = inputname(2);
% eval([var_name '= data']);
% 
% try
%     save(fname,var_name,'-append');
% catch
%     save(fname,var_name);
% end
% 
% end

