function ifErrorStop()
%IFERRORSTOP �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
w_edb_errorid = evalin('base', 'w_edb_errorid');
if w_edb_errorid ~= 0
    stop
end

