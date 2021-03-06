function [s] = load_sno_iasi_cris_asl_mat(sdate, edate, xwns, cris_res, src, vers)
%
% function load_sno_iasi_cris_asl_mat() loads up radiances for a selected number
%   of channels, specified by CrIS channel number, from the ASL SNO mat files 
%   and for the specified year and months. 
%   Unlike the sister function 'read_sno...'
%   this function cacluates statistics during load and subsets of CrIS FOV.
%
% Synopsis: load_sno_iasi_cris_asl_mat('sdate','edate',[channel list], cris_res, src, vers);
%           sdate: start date as string: 'YYYY/MM/DD'
%           edate: end date as string:   'YYYY/MM/DD'
%           N.B. Only accepts the same year.
%           xwns: wavenumbers to load. 
%           eg [900:920] or: 
%             LoRes:  LW:[1:713], MW:[714:1146], SW:[1147:1317];
%             MidRes: LW:[1:715], MW:[716:1366], SW:[1367:1683];
%             HiRes:  LW:[1:713], MW:[714:1578], SW:[1579:2211];
%                  [1:1269] (645  - 1100) cm-1
%                  [1270:2160] (1100 - 1615) cm-1
%           cris_res:  CrIS spectral resolution {'low','medium','high'}
%           src:  [M1, M2]. mission numbers: iasi-1 or iasi-2 (MetOp-A or -B) 
%                 and cris-1 or cris-2 (NPP or JPSS-1), 
%           vers: string. version reference for data set (found at end of file
%               name).
%
% Output:  Two structures of arrays. 
%             s: the SNO geo, time and related vector fields.
%             a: whole spectrum averages and first moment.
%
%
% Notes: 
%        The CrIS CCAST spectral resolution is hard-wired for LR (low-res).
%        The IASI spectra are apodized.
%
% Dependencies: i) nominal IASI and CrIS w/2 guard channels per edge frequency grids.
%    iii) fixed path and file name syntax for SNO files.
%
% Notes: i) No QA is applied. ii) time separation of SNO pairs from file is positive-only
%    so is recomputed here.
%
% Author: C. L. Hepplewhite, UMBC/JCET
%
% Version: 24-October-2017
% 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd /home/chepplew/gitLib/asl_sno/run

addpath /asl/packages/airs_decon/source             % hamm_app.m
%addpath /asl/matlib/aslutil                         % rad2bt.m
addpath /home/chepplew/gitLib/asl_sno/source/
%addpath /home/strow/Git/breno_matlab/Math           % Math_bin.m
addpath /home/chepplew/gitLib/airs_deconv/source    % seq_match.m
addpath /home/chepplew/myLib/matlib/math            % remove_6sigma 

s = struct;

% Check number of input arguments
if(nargin ~= 6) error('Please enter all 6 input arguments'); return; end

% Check CrIS resolution (high or low)
%cris_res='high';
cris_res = upper(cris_res);
if(strcmp(cris_res,'HIGH'))   CR='HR'; ncc=2223; end
if(strcmp(cris_res,'MEDIUM')) CR='MR'; ncc=1683; ni2cc=1691; end
if(strcmp(cris_res,'LOW'))    CR='LR'; ncc=1317; end
s.res = lower(cris_res);

% Default processing origin & sno revision:
MX = 'ASL';

% Assign version string, vers:
allvers = {'','noaa_pon','noaa_poff','v20a','v20d','nasa'};
vers = lower(vers);
if(~ismember(vers,allvers)); error('version is unrecognized'); return; end
if(contains(vers,'noaa'))
  vers = [upper(vers(1:4)) lower(vers(5:end))];
  MX   = vers;
  rev = 'noaa';
else
  rev = vers;
end
s.vers = vers;

% Check mission numbers
if(length(src) ~=2) error('Need IASI and CRIS mission numbers'); return; end
junk = ismember(src,[1,2]);
if(~all(junk)) error('Mission numbers can only be 1 or 2 for now'); return; end
disp(['you have selected IASI-' num2str(src(1)) ' and CRIS-' num2str(src(2))]);
if(src(1) == 1) IX = '';  end
if(src(1) == 2) IX = '2'; end
if(src(2) == 1) CX = '';  end
if(src(2) == 2) CX = '2'; end
s.src = src;

% Process and check the date strings
posYrs = [2002:2019];
posMns = [1:12];
whos sdate; disp([sdate ' to ' edate]); fprintf('\n');
try 
   D1 = datenum(sdate,'yyyy/mm/dd');
   D2 = datenum(edate,'yyyy/mm/dd');
catch
   error('Incorrect Date Format')
   return
end
s.dtime1 = datetime(D1,'convertFrom','datenum');
[nYr1 nMn1 nDy1] = datevec(D1);
[nYr2 nMn2 nDy2] = datevec(D2);
%%if(nYr1 ~= nYr2) error('Use same year only'); return; end
cYr1   = sdate(1:4);     cMn1 = sdate(6:7);     cDy1 = sdate(9:10);
cYr2   = edate(1:4);     cMn2 = edate(6:7);     cDy2 = edate(9:10);

  junk = sprintf('%4d/%02d/%02d',nYr1-1,12,31);
jdy1   = datenum(sdate)-datenum(junk);  clear junk;           % needed for data directory
  junk = sprintf('%4d/%02d/%02d',nYr2-1,12,31);
jdy2   = datenum(edate)-datenum(junk);  clear junk;           % needed for data directory
s.sdate = sdate;
s.edate = edate;
   
% ************* get list and subset date range  ********************

if(nYr2 > nYr1)
  disp('yr2 > yr1')
  dp1 = ['/home/chepplew/data/sno/iasi' IX '_cris' CX '/' MX '/' CR '/' cYr1 '/'];
  dp2 = ['/home/chepplew/data/sno/iasi' IX '_cris' CX '/' MX '/' CR '/' cYr2 '/'];
  lst1 = dir([dp1 'sno_iasi_cris_asl_*' lower(vers) '.mat']);
  lst2 = dir([dp2 'sno_iasi_cris_asl_*' lower(vers) '.mat']);
  snoLst = [lst1; lst2];
elseif (nYr2 == nYr1)
  disp('yr2 = yr2')
  dp1  = ['/home/chepplew/data/sno/iasi' IX '_cris' CX '/' MX '/' CR '/' cYr1 '/'];
  snoLst = dir(strcat(dp1, 'sno_iasi_cris_asl_*',lower(vers),'.mat'));
end
disp(['Found ' num2str(numel(snoLst)) ' SNO files']);

if(numel(snoLst) < 1) error('No SNO files found'); return; end;

% subset range by date as requested:
ifn1 = 1;
for ii=1:length(snoLst)
  %lst3(ii).name

  junk = regexp(snoLst(ii).name,'[0-9]','match');
  Dx = datenum(cell2mat(junk(1:8)),'yyyymmdd');
  if(Dx < D1)  ifn1 = ii+1; end                  % disp(num2str(ii)); end
  if(Dx <= D2) ifn2 = ii; end
end

disp(['src: ' num2str(src) ' cris_res: ' cris_res ' vers: ' vers])
disp(['Source dir: ' snoLst(1).folder]);
fprintf(1,'Loading %d SNO files from: %s to %s\n',(ifn2-ifn1+1),snoLst(ifn1).name, ...
        snoLst(ifn2).name);
s.dp    = dp1;
s.flist = snoLst(ifn1:ifn2);

% ******  BUG HACK for error in NOAA SDR CrIS frequency grid:  ******
%{
load('/home/chepplew/projects/iasi/f_iasi.mat');               % f_iasi [8641 x 1]
xfc=load(strcat(snoLst(1).folder,'/', snoLst(1).name),'fc','rc','fi2c','ri2c');
if( length(xfc.fc) ~= size(xfc.rc,1) )
  opts = struct;
  opts.hapod    = 1;
  opts.user_res = 'hires';
  opts.inst_res = 'hires3';
  opts.nguard   = 2;
  addpath /asl/packages/iasi_decon                      % iasi2cris
  addpath /asl/packages/ccast/source                    % inst_params
  [~, fc] = iasi2cris(ones(8461,1), f_iasi, opts);
end
%}
% Check channel numbers entered correctly
%if(min(xchns) < 1 || max(xchns) > 1317 ) fprintf(1,'Wrong channel numbers used\n'); end

% load IASI and CrIS channels (and iasi2cris channels if needed)
load('/home/chepplew/projects/iasi/f_iasi.mat');               % f_iasi [8641 x 1]
if(strcmp(CR,'LR'))
  load('/home/chepplew/projects/cris/cris_freq_2grd.mat'); 
  fcris = vchan;  icris = ichan; 
end
if(strcmp(CR,'MR'))
  load('/home/chepplew/myLib/data/cris_mr_freq_2grd.mat'); 
  fcris = vchan;  icris = ichan;
  load('/home/chepplew/myLib/data/freq_iasi2cris_midres.mat');    % fi2c
end
if(strcmp(CR,'HR'))
  load('/home/chepplew/myLib/data/cris_hr_freq_2grd.mat'); 
  fcris = vchan;  icris = ichan;                                   % fcris 
  load('/home/chepplew/myLib/data/freq_iasi2cris_hires.mat');      % fi2c
end  
whos *cris 
% Get over-lapping IASI channels
% iasi2cris for MR returns more channels than CrIS at MR.
%if(strcmp(CR,'LR'))
%  [cchns, ~] = intersect(icris, xchns);
%  dchns      = cchns;
%  ichns      = [find(f_iasi >= fcris(cchns(1)),1): find(f_iasi >= fcris(cchns(end)),1)];
%    
%end
%if(strcmp(CR,'MR')) 
%  [cchns,~]  = intersect(icris, xchns); 
%  ichns      = [find(f_iasi >= fcris(xchns(1)),1): find(f_iasi >= fcris(xchns(end)),1)]; 
%  [~, dchns] = intersect(fi2c, fcris(cchns));
%  [ftmp, ~]  = intersect(fcris(cchns),fi2c(dchns));
%end
%if(strcmp(CR,'HR'))
%  %xx = load('~/myLib/data/cris_hr_freq_2grd.mat'); fcris = xx.vchan; icris = xx.ichan;
%  [~, cchns] = intersect(icris, xchns);
%  [~, dchns] = intersect(fi2c, fcris(cchns));
%  ichns      = [find(f_iasi >= fcris(cchns(1)),1): find(f_iasi >= fcris(cchns(end)),1)];
%  [ftmp, ~]  = intersect(fcris(cchns),fi2c(dchns));
%  [~, cchns] = intersect(fcris, ftmp);
%end
%whos *chns 
% Get the IASI channels to load
ichns = [find(f_iasi >= xwns(1),1) : find(f_iasi >= xwns(end),1)];

% if all channels are requested - load all IASI (NB beware of memory demand)
if(length(xwns) == length(fcris)) ichns = [1:8461]; end


% ********************* load up SNO data *****************************
s.tdiff = [];    s.rc = [];    s.ri = [];      s.rd = [];  s.itime = [];  s.ctime = []; 
 s.clat = [];  s.clon = []; s.dist  = [];    s.ilat = [];   s.ilon = [];  s.csolz = [];  
s.iqual = []; s.clnfr = [];  s.ifov = [];    s.cfov = []; s.prcver = [];

for ifn = ifn1:ifn2;
  vars = whos('-file',strcat(snoLst(ifn).folder,'/',snoLst(ifn).name));
  if( ismember('ri', {vars.name}) & ismember('rc', {vars.name}) & ...
      (ismember('ri2c', {vars.name}) || ismember('i2rc',{vars.name})) )  
    load(strcat(snoLst(ifn).folder,'/', snoLst(ifn).name));
    % test for origin of CrIS spectra, select which cchns to load
    %%if( all(strcmp(cris_res,{'HIGH','LOW'})) )      %cchns = cinds.fsr; fcris = cfreq.fsr; nvc = 1309;
      itmp  = [find(fc >= xwns(1),1) : find(fc >= xwns(end),1)];
      ftmp  = fc(itmp);
      [fd, dchns]    = intersect(fi2c, ftmp);
      [fcris, cchns] = intersect(fc, fd);
      nvc   = length(fcris);
    %%elseif( all(strcmp(cris_res,{'LOW','LOW'})) )
      %cchns = cinds.nsr; fcris = cfreq.nsr; nvc = 1317;
    %%  itmp  = [find(fc >= xwns(1),1) : find(fc >= xwns(end),1)];
    %%  ftmp  = fc(itmp);
    %%  [fd, dchns]    = intersect(fi2c, ftmp);
    %%  [fcris, cchns] = intersect(fc, fd);
    %%  nvc   = length(fcris);
    %%end

    if( ismember('i2rc',{vars.name})) ri2c = i2rc; end
    if( size(rc,2) ~= size(sno.clat,1) ) disp(['fn: ' num2str(ifn) ' size error']); 
      continue; end
    %if( size(ri,1) == 8461 & size(rc,1) == ncc & size(ri2c,1) == ni2cc ) 
    if( size(ri,1) ~= 8461) ri = ri'; end
      rc_ham    = single(hamm_app(double(rc)));
      s.rc      = [s.rc, rc(cchns,:)];
      s.ri      = [s.ri, ri(ichns,:)];
      s.rd      = [s.rd, ri2c(dchns,:)];
      s.ctime   = [s.ctime; sno.ctim];
      s.itime   = [s.itime; sno.itim];
      s.clat    = [s.clat;  sno.clat];         s.clon = [s.clon;  sno.clon];
      s.ilat    = [s.ilat;  sno.ilat];         s.ilon = [s.ilon;  sno.ilon];
      s.ifov    = [s.ifov;  sno.ifov];
      s.cfov    = [s.cfov;  sno.cfov];
      s.csolz   = [s.csolz; sno.csolz];
      s.tdiff   = [s.tdiff; sno.tdiff];
      s.dist    = [s.dist;  sno.dist'];
      s.iqual   = [s.iqual; sno.iqual];
      %s.prcver  = [s.prcver; g.process_version];
    %end
  else
    disp(['Skipping: ' snoLst(ifn).name]);
  end 
  fprintf(1,'.');
end                        % end for ifn
fprintf(1,'Loaded %d SNO pairs\n',size(s.ilat,1));

s.fi = f_iasi;  s.fd = fi2c;  s.fc = fcris;   % record fcris not fc
s.cchns  = cchns;
s.ichns  = ichns';
s.dchns  = dchns;
s.hamm   = true;

% Check QA
iok  = ':'; % find(s.iqual == 0);
ibad = [];  % find(s.iqual > 0);

% Remove 6-sigma
icbias = s.rd - s.rc;
whos icbias
disp(['Removing outliers']);
clear gx;
for i=1:length(cchns)
   n  = single(remove_6sigma(icbias(i,:)));
   nn = single(remove_6sigma(icbias(i,n)));
   gx(i).n = n(nn);
end

% Now find unique set of bad SNO samples
ux = [];
[~, psz] = size(icbias);
for i=1:length(cchns)
   ux = [ux setdiff(1:psz,gx(i).n)];
end
sbad   = unique(ux);
s.r6s  = single(setdiff(1:psz,ux));
disp(['  ' num2str(numel(ux)) ' outliers removed']);
clear gx n nn ux icbias;

% combine iqual and r6s
s.ibad   = sort(unique([ibad; sbad']));
s.iok    = setdiff(1:psz, s.ibad);
 
% ******************** END *******************

%{
% find highest l1cProc value for each channel 
% [0:unchanged, 64:cleaned, see l1cReason, 128:synthesized, 128+1:dummy fill]
% highest l1cReason: [0:preserved, 1:gap, 3, 4, 5, 8, 9, 10, 11, 12, 129:?]
for i = 1:2645
  chanProc(i) = max(s.l1cp(:,i));
  chanReas(i) = max(s.l1cr(:,i));
end
presChanID = find(chanReas == 0);    % what chance - have 2378 channels preserved

% Find the L1b channel IDs corresponding to these L1C preserved chan IDs.
b=sort(f2645(presChanID));
a=sort(fa);
[ai,bi]=seq_match(a,b);     %a(ai) are the L1b set that are preserved

% find which of these apply to the AIRS2CrIS subset.
c = sort(fd);
[ci,bi] = seq_match(c,b);


% Compute averages and standard deviations

ratpm=0; rctpm=0; rdtpm=0; ratps=0; rctps=0; rdtps=0; ratxs=0; rctxs=0; rdtxs=0;
for i = 1:numel(a.nSam)
  ratpm = ratpm + a.avra(:,i).*a.nSam(i);    rctpm = rctpm + a.avrc(:,i).*a.nSam(i);
  rdtpm = rdtpm + a.avrd(:,i).*a.nSam(i);
  ratps = ratps + ( a.sdra(:,i).*a.sdra(:,i) + a.avra(:,i).*a.avra(:,i) )*a.nSam(i);
  rctps = rctps + ( a.sdrc(:,i).*a.sdrc(:,i) + a.avrc(:,i).*a.avrc(:,i) )*a.nSam(i);
  rdtps = rdtps + ( a.sdrd(:,i).*a.sdrd(:,i) + a.avrd(:,i).*a.avrd(:,i) )*a.nSam(i);
end

a.gavrm = ratpm/sum(a.nSam);  a.gcvrm = rctpm/sum(a.nSam);  a.gdvrm = rdtpm/sum(a.nSam);
a.gadrs = real(sqrt( ratps/sum(a.nSam) - a.gavrm.*a.gavrm ));
a.gcdrs = real(sqrt( rctps/sum(a.nSam) - a.gcvrm.*a.gcvrm ));
a.gddrs = real(sqrt( rdtps/sum(a.nSam) - a.gdvrm.*a.gdvrm ));
a.garse = a.gadrs/sqrt(sum(a.nSam));   a.gcrse = a.gcdrs/sqrt(sum(a.nSam));
a.gdrse = a.gddrs/sqrt(sum(a.nSam));
%}

%{
% plot checks
phome   = '/home/chepplew/projects/sno/iasi_cris/figs/';
cyr     = num2str(year(s.dtime1));
[ns nz] = size(s.rc);
cbt = real(rad2bt(s.fc(s.cchns), s.rc(:,s.iok)));
ibt = real(rad2bt(s.fi(s.ichns), s.ri(:,s.iok)));
dbt = real(rad2bt(s.fc(s.cchns), s.rd(:,s.iok)));
cbm = nanmean(cbt,2);
ibm = nanmean(ibt,2);
dbm = nanmean(dbt,2);
btmbias = nanmean(cbt - dbt,2);
btmstd  = nanstd(cbt - dbt, 0,2);
  whos cbt ibt dbt cbm ibm dbm btmbias btmstd;

% in case of LW band:
cch = find(s.fc(s.cchns) > 900,1);
ich = find(s.fi(s.ichns) > 900,1);

dbtbin = 2; btbins = [190:dbtbin:300]; 
btcens = [btbins(1)+dbtbin/2:dbtbin:btbins(end)-dbtbin/2];
pdf_cbt = histcounts(cbt(cch,:),btbins);
pdf_ibt = histcounts(ibt(ich,:),btbins);
pdf_dbt = histcounts(dbt(cch,:),btbins);

pdf_btbias = histcounts(cbt - dbt, [-20:0.2:20]);                  % All channels
pdf_btbias = histcounts(cbt(cch,:) - dbt(cch,:), [-20:0.2:20]);    % Single channel

figure(1);clf;simplemap(s.ilat, s.ilon, s.tdiff*24*60);
  title([cyr ' I1:C ASL SNO Obs delay minutes']);
  %aslprint([phome cyr '_I1C_ASL_SNO_map_delay.png']);
figure(1);clf;simplemap(s.ilat, s.ilon, s.dist); 
figure(1);clf;simplemap(s.ilat, s.ilon, ibt(ich,:)');
figure(1);clf;simplemap(s.ilat, s.ilon, (cbt(cch,:) - dbt(cch,:))');

figure(2);plot(btcens,pdf_cbt,'.-', btcens,pdf_ibt,'.-');legend('CrIS','IASI');
  xlabel('BT bin (K)');ylabel('bin population');grid on;
  title([cyr ' I1:C SNO 900wn channel population']);
  %aslprint([phome cyr '_I1C_ASL_SNO_900wn_pdf.png']);

figure(3);clf;plot(s.fc(s.cchns),cbm,'-', s.fi(s.ichns),ibm,'-', ...
          s.fd(s.cchns),dbm,'-');grid on;legend('CrIS','IASI','I2C')
  xlabel('wavenumber cm^{-1}'); ylabel('BT (K)'); xlim([640 1100]); 
  % xlim([1200 1780]); xlim([2140 2560])
  title([cyr ' IASI1:CrIS SNO Mean BT (LW) ' num2str(nz) ' samples']);
  % aslprint([phome cyr '_I1C_ASL_SNO_meanBT_LW.png']);

figure(4);clf;semilogy([-19.9:0.2:19.9], pdf_btbias,'.-');grid on;axis([-16 16 10 1E7]);
  xlabel('BT bin (K)');ylabel('Bin population');
  title([cyr ' SNO CrIS minus IASI 900 cm-1 channel']);
  %aslprint([phome cyr '_I1C_ASL_SNO_900wn_bias_pdf.png'])
  
figure(5);clf;  % plotxx(s.fa(s.achns),btmbias,'-',s.fa(s.achns),btmstd/sqrt(nz),'-');
[hax,hl1,hl2] = plotyy(s.fc(s.cchns),btmbias,s.fc(s.cchns),btmstd/sqrt(nz));grid on;
   hax(1).YTick = [-0.6:0.2:0.6]; xlim(hax(1),[640 1100]); ylim(hax(1),[-1 1]);
   xlim(hax(2),[640 1100]); ylim(hax(2),[0 0.08]);
   ya2=ylabel(hax(2),'Std. error (K)');set(ya2, 'Units', 'Normalized', 'Position', [1.05, 0.7, 0]);
   xlabel(hax(1),'Wavenumber (cm^{-1})');
   ylabel(hax(1),'CrIS - IASI (K)');legend('Mean bias CrIS-IASI','Std.Err CrIS-IASI');
   title([cyr ' CrIS - IASI SNO Mean Bias, std.Err']);
figure(5);clf;hax = gca;
  yyaxis left;  ha1 = plot(s.fc(s.cchns),btmbias,'-');      ylabel('CrIS - IASI (K)');
  hax.YLim=([-0.8 0.8]);
  yyaxis right; ha2 = plot(s.fc(s.cchns),btmstd/sqrt(nz));  ylabel('std. error (K)')
  yyaxis right; hax.YLim = ([0 0.08]);  hax.XLim=([640 1100]);grid on;
  xlabel('wavenumber cm^{-1}');title([cyr ' CrIS - IASI SNO Mean Bias, std.Err']);
   %aslprint([phome cyr '_I1C_ASL_SNO_meanBias_stdErr_LW.png']);
%}
