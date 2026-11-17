function tel = truncate_telemetry(tel, T)
% TRUNCATE_TELEMETRY  Keep the first T frames of every stream.
f = fieldnames(tel);
for i = 1:numel(f)
    v = tel.(f{i});
    if isnumeric(v) && size(v, 1) > T
        tel.(f{i}) = v(1:T, :);
    end
end
tel.T = T;
tel.timeVector = tel.timeVector(1:T);
end
