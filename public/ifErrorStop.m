function ifErrorStop()
%IFERRORSTOP 此处显示有关此函数的摘要
%   此处显示详细说明
w_edb_errorid = evalin('base', 'w_edb_errorid');
if w_edb_errorid ~= 0
    stop
end

