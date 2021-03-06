function proc_airs_to_cris_mat()

% function proc_airs_to_cris()
%
% Synopsis: converts AIRS spectrum to CRIS and appends the data to the
%   original file (as required by downstream SNO processors).
%
% Input Parameters: jobNam: string supplied by mstr_airs_to_cris_mat.m
%       
%
% Assumptions: The source files are .mat files and can be written to.
%
%

addpath /asl/packages/ccast/source                %
addpath /asl/matlib/h4tools                       %  
addpath /asl/packages/airs_decon/source           %

nslurm  = str2num(getenv('SLURM_ARRAY_TASK_ID'));

% check job list file:
res = exist('./JobList.txt','file');
if(res ~= 2) fprintf(1,'Error: JobList file not found\n'); exit; end
FH = fopen('./JobList.txt','r');
 junk = textscan(FH,'%s');                 % cell array
fclose(FH);
instr = cell2mat(junk{1}(nslurm));
[xpath,xnam,ext] = fileparts(instr);

% deconvolution setup
bfile = '/asl/s1/chepplew/tmp/bconv4.mat';        % deconvolution temp file
dvb = 0.1;                                        % deconvolution frequency step
fig = 'fig';                                      % plot type
dohamm = 1;
sfile = '/asl/matlab2012/srftest/srftables_m140f_withfake_mar08.hdf';
cfreq = load('/home/chepplew/gitLib/airs_deconv/test/freq2645.txt');
opt5.dvb    = dvb;
opt5.bfile  = bfile;
opt5.hapod  = 1;             % set airs2cris to perform Hamming apodization

  g = load( instr );
  junk = regexp(xnam,'(?<=clh_)[\d.]+(?=_)','match');
  fsav = strcat(xpath, 'airs2cris_', junk, '.mat');
  
  % convert AIRS to CRIS
  drad = [;];
  sz     = size(g.ra,2);
  lftovr = mod(sz,1000);
  rnds   = fix( (sz-lftovr)/1000);     % if samples < 5000, rnds = 0.
  ps = 1; pe = 0;
  if (rnds)
    for jj = 1:rnds
      pe = ps + 1000 - 1;
      fprintf(1,'.'); %fprintf('%5d %5d\n', ps,pe);
      [rr5, ff, pp] = airs2cris(g.ra(:,ps:pe), cfreq, sfile, opt5);
      drad = [drad, rr5]; 
      ps = ps + 1000;
    end
  end
  if (lftovr >= 1)
    fprintf(1,'.');   %    fprintf('%5d %5d\n', ps,pe);
    pe = ps + lftovr - 1;
    [rr5, ff, pp] = airs2cris(g.ra(:,ps:pe), cfreq, sfile, opt5);
    drad = [drad, rr5];
  end
  fprintf(1,'\n');
  frq = ff;
  
  %%save(fsav, 'drad', 'frq')

end
