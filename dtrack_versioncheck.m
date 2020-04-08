function [syst, thisv] = dtrack_versioncheck(verbose)

if nargin<1, verbose = true; end

v       = ver('matlab');
thisv   = str2double(v.Version);
syst    = computer;

if verbose
    switch syst
        case 'PCWIN'
            disp(['You are running MATLAB version ' v.Version ' on a 32-bit Windows PC.']); osfine = 1;
        case 'PCWIN64'
            disp(['You are running MATLAB version ' v.Version ' on a 64-bit Windows PC.']); osfine = 1;  
        case 'MACI'
            disp(['You are running MATLAB version ' v.Version ' on a 32-bit Mac.']); osfine = 1;
        case 'MACI64'
            disp(['You are running MATLAB version ' v.Version ' on a 64-bit Mac.']); osfine = 1;
        case 'GLNX86'
            disp(['You are running MATLAB version ' v.Version ' on a 32-bit Linux system.']); osfine = 0;
        case 'GLNXA64'
            disp(['You are running MATLAB version ' v.Version ' on a 64-bit Linus system.']); osfine = 0;
        otherwise
            disp(['You are running MATLAB version ' v.Version ' on an unknown operating system.']); osfine = 0;
    end
    if verLessThan('matlab', '7.7')
        warning('This program has only been tested for version 7.7 and above. Please report any errors or bugs.');
    end
    if ~osfine
        warning('This program has not been tested on your operating system. Please report any errors or bugs.');
    end
    if ~verLessThan('matlab', '7.7') && osfine
        disp('This program should be running fine.');
    end
end