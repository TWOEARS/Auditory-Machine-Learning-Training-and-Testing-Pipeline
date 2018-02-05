function freemem = memReport()

try
    if ispc
        usermem = memory;
        freemem = usermem.MemAvailableAllArrays / 1e9;
    elseif isunix
        [~,w] = unix( 'free | grep Mem' );
        stats = str2double( regexp( w, '[0-9]*', 'match' ) );
        freemem = (stats(3) + stats(end)) / 1e6;
    end
catch err
    warning( err.message );
end

end
