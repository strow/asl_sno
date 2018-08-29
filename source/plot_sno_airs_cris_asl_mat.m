function plot_sno_airs_cris_asl_mat(r,s)
%function: plot_sno_airs_cris_asl_mat(r)
%
% plot_sno_airs_cris_asl_mat.m
%
% first run:   s  = load_sno_airs_cris_asl_mat(sdate1, sdate2, xchns, src);
% then run:    r  = stats_sno_airs_cris_asl_mat(s);
%
%
% plot options
% set(gcf,'Resize','off');

fa   = r.fa;
fc   = r.fc;
fd   = r.fd;
vers = strrep(r.vers,'_','.');
res  = r.res;
src  = r.src;    %  (s/craft npp = 1, j01=2);
band = r.band;   %  LW, MW or SW

if(strcmp(res,'HIGH')) CR='HR'; end
if(strcmp(res,'LOW'))  CR='LR'; end
phome = ['/home/chepplew/projects/sno/airs_cris/' CR '/figs/'];

xyr  = year(datetime(datenum(r.sdate),'convertfrom','datenum'));
cyr  = num2str(xyr);
smn  = month(datetime(datenum(r.sdate),'convertfrom','datenum'),'shortname');
smn  = lower(cell2mat(smn));
emn  = month(datetime(datenum(r.edate),'convertfrom','datenum'),'shortname');
emn  = lower(cell2mat(emn));
part = '';

% Initialization
cc=fovcolors;       % Howard's 9 line colors uas as: plot(...,'-','color',cc(i,:))

pfnam_pref = ['sno_ac' num2str(src) '_' lower(CR) '_' lower(band) ...
              '_' cyr smn '-' emn '_'];

wnbnd = [floor(fc(1)-10) ceil(fc(end)+10)];

% ----------------------------------------------------------------
%                     PLOTTING SECTION 
% ----------------------------------------------------------------

figure(1);clf;plot(r.fa, r.abm,'-', r.fc, r.cbm,'-', r.fd, r.dbm,'-');
  grid on;legend('AIRS','CrIS','A2C','Location','southEast');
% ------------ Maps ----------------------
if(strcmp(band,'LW'))
  ach = find(r.fa>900,1);  
  cch = find(r.fc>900,1);  
  dch = find(r.fd>900,1);
  wvn='900';
end
if(strcmp(band,'MW'))
  ach = find(r.fa>1231,1); 
  cch = find(r.fc>1231,1); 
  dch = find(r.fd>1231,1);
  wvn='1231';
end
if(strcmp(band,'SW'))
  ach = find(r.fa>2410,1); 
  cch = find(r.fc>2410,1); 
  dch = find(r.fd>2410,1);
  wvn='2410';
end
title2=['ASL AC.' num2str(src) ' SNO ' r.sdate ' to ' r.edate ' ' band ' overview'];
fh2=figure(2);clf;set(gcf,'Resize','Off'); set(gcf,'Position',fh2.Position+[0 0 420 240]);
  subplot(2,2,1); simplemap(s.cLat, s.cLon, s.tdiff*24*60);title('Delay AIRS-CrIS mins');
  subplot(2,2,2); simplemap(s.cLat, s.cLon, s.dist); title('Separation deg');

  junk = r.cbt(cch,:)';
  subplot(2,2,3);simplemap(s.cLat(s.ig), s.cLon(s.ig), junk);title('CrIS BT (K)');
  subplot(2,2,4);simplemap(s.cLat(s.ig), s.cLon(s.ig), r.btbias(cch,:)');
    hcb = colorbar;ylabel(hcb,[wvn ' cm^{-1} dBT (K)']);
  title('SNO Bias AIRS minus CrIS (K)');
  annotation('textbox', [0 0.9 1 0.1], 'String', title2, 'fontSize',16,...
    'EdgeColor', 'none','HorizontalAlignment', 'center')
  %saveas(gcf,[phome 'maps'],'');
  
% ------------ Histograms -----------------
pc_diff_pdf = 100.*(r.pdf_cbt - r.pdf_dbt)./r.pdf_cbt;
title3=['ASL AC.' num2str(src) ' SNO ' r.sdate ' to ' r.edate ' ' wvn ' cm^{-1} pdfs ' vers];
fh3=figure(3);clf;set(gcf,'Resize','off');set(fh3,'Position',fh3.Position+[0 0 420 240]);
  h1 = subplot(221);plot(r.btcens,r.pdf_cbt(cch,:),'.-', r.btcens,r.pdf_dbt(dch,:),'.-',...
    r.btcens,r.pdf_abt(ach,:),'-'); grid on;xlim([190 330]);
    xlabel('Scene BT bin (K)');ylabel('Number in bin');legend('CrIS','AIRStoCrIS','AIRS')
    title('')
  h2=subplot(223);plot(r.biascens, r.pdf_bias(cch,:), '.-');grid on;
    xlabel('bin BT (K)');ylabel('population');legend([wvn ' cm^{-1}']);
    title('AIRS:CrIS SNO bias');
  h3=subplot(222);plot(r.btcens,r.pdf_cbt(cch,:),'.-', r.btcens,r.pdf_dbt(dch,:),'.-'); 
    grid on;xlim([200 320]);legend('CrIS','AIRS');xlabel('Tb (K)');
    title('');
  h4=subplot(224);plot(r.btcens, pc_diff_pdf(dch,:),'.-');
    grid on;xlim([200 320]);ylabel('% diff CrIS-AIRS');
    title('PDF difference')
  annotation('textbox', [0 0.9 1 0.1], 'String', title3, 'fontSize',16,...
    'EdgeColor', 'none','HorizontalAlignment', 'center')
  %saveas(gcf,[phome  pfnam_pref 'pdfs.fig'],'fig');
  
%figure(2);clf;plot(btcens,pdf_sim_cbt(ich,:),'.-', btcens,pdf_dbt(ich,:),'.-'); grid on;

%figure(2);clf;plot(btcens, 0.25*pdf_nbr_cbt(ich,:),'.-', btcens, pdf_cbt(ich,:),'.-');
%figure(2);clf;plot(btcens, 0.50*pdf_nbr_abt(ich,:),'.-', btcens, pdf_abt(ich,:),'.-');
%figure(2);clf;plot(btcens, 0.50*pdf_nbr_dbt(ich,:),'.-', btcens, pdf_dbt(ich,:),'.-');

%figure(3);clf;plot(r.biascens, r.pdf_bias(cch,:), '.-');grid on;
%  xlabel('bin BT (K)');ylabel('population');legend('900 cm^{-1}');
%  title('2018d005 AIRS:CrIS-2 SNO bias hist');
  
% ------------ fractional PDF differences --------------
%{
pc_diff_nbr = 100.*(pdf_nbr_cbt - pdf_nbr_abt)./pdf_nbr_cbt;
figure(2);clf;
 h1=subplot(2,1,1);plot(btcens,pdf_nbr_cbt(4,:),'.-', btcens,pdf_nbr_abt(4,:),'.-'); grid on;
 title('Nbr. Obs count by 900cm-1 temp. bin');axis([200 330 0 Inf]);
 %h2=subplot(2,1,2);plot(btcens,pdf_cbt(4,:),'.-', btcens,pdf_abt(4,:),'.-'); grid on;xlim([300 320]);
 %legend('CrIS','AIRS');xlabel('Tb (K)');
 h2=subplot(2,1,2);plot(btcens, pc_diff_nbr(4,:),'.-');grid on;ylabel('% diff CrIS-AIRS');
 xlim([200 330])

figure(2);clf;plot(btcens, (pdf_sim_cbt(4,:) - pdf_cbt(4,:))./pdf_cbt(4,:),'.-');hold on;
   plot(btcens, (pdf_sim_abt(4,:) - pdf_abt(4,:))./pdf_abt(4,:),'.-');                      
   xlim([200 330]); grid on; legend('CrIS','AIRS');
   title('Fraction difference AIRS and CrIS neighbors vs SNO'); 
%}
% ------------ Simple Bias Stats -------------------------
figure(4);clf;plot(r.fd,r.bias_mn,'-');
%
wnbnd = [floor(r.fc(1)-10) ceil(r.fc(end)+10)];
title4=['AC.' num2str(src) ' SNO ' r.sdate ' to ' r.edate ' Mean Bias ' band ' ' vers ''];
fh4=figure(4);clf;set(fh4,'Resize','Off');set(fh4,'Position',fh4.Position+[0 0 280 210]);
  h1=subplot(221);plot(r.fc,r.bias_mn,'-', r.fc,10*r.btser,'-');  
  axis([wnbnd(1) wnbnd(2) -0.8 0.8]);grid on;
  legend(['CrIS.' num2str(src) ' - AIRS','10*std.err.']);
  xlabel('wavenumber cm^{-1}');ylabel('CrIS minus AIRS (K)');

  h2=subplot(222);hold on; for i=1:9 plot(r.fc,r.fov(i).mbias,'-','color',cc(i,:)); end
  axis([wnbnd(1) wnbnd(2) -0.8 0.8]);grid on;
  legend('1','2','3','4','5','6','7','8','9','Location','eastOutside',...
         'orientation','vertical');
  xlabel('wavenumber cm^{-1}');ylabel('CcIS minus AIRS (K)');
% with FOV 5 as the reference
  h3=subplot(223);hold on;
  for i=[1:4 6:9] plot(r.fc,r.fov(i).mbias - r.fov(5).mbias,'-','color',cc(i,:)); end
  grid on; axis([wnbnd(1) wnbnd(2) -0.4 0.4]); 
  legend('1','2','3','4','6','7','8','9','Location','eastOutside');
  xlabel('wavenumber cm^{-1}');ylabel('dBT (K)');
  title('C minus A rel. FOV 5')
  annotation('textbox', [0 0.9 1 0.1], 'String', title4, 'fontSize',16,...
    'EdgeColor', 'none','HorizontalAlignment', 'center')
  %saveas(gcf,[phome pfnam_pref 'mean_bias.fig'],'fig');

%{  
% Double difference (must have loaded two sets: ac1_fov and ac2_fov)
figure(4);clf;hold on; 
  for i=1:9 plot(fc, r.fov(i).mbias - r2.fov(i).mbias,'-','color',cc(i,:));end
  axis([wnbnd(1) wnbnd(2) -0.4 0.4]);grid on;
    legend('1','2','3','4','5','6','7','8','9',...
           'Location','eastOutside'); %,'orientation','horizontal');
  xlabel('wavenumber cm^{-1}');ylabel('A:CrIS.1 minus A:CrIS.2 (K)');
  title([{'2018Jan SNO mean bias of'} {'A:C1 minus A:C2.a2.test1 vs FOV MW'}]);
  %saveas(gcf, [phome 'sno_ac1_ac2_dble_diff_lr_lw_2018feb-jun.fig'],'fig')

nf4 = figure(4);clf;  set(gcf,'Resize','off');
set(nf4,'Position',nf4.Position+[0,0,280 210]);
h1=subplot(3,1,1);hold on;for i=1:9 plot(fc, r3.fov(i).btser,'-','color',cc(i,:));end;
  grid on;legend('1','2','3','4','5','6','7','8','9',...
                 'Location','north','orientation','horizontal');
  annotation('textbox',[.2 .5 .3 .3],'String','A:C1','FitBoxToText','on');
h2=subplot(3,1,2);hold on;for i=1:9 plot(fc, r2.fov(i).btser,'-','color',cc(i,:));end;
  grid on;legend('A:C2.a2v4ref')
h3=subplot(3,1,3);hold on;for i=1:9 plot(fc, r1.fov(i).btser,'-','color',cc(i,:));end;
  grid on;legend('A:C2.a2test1')
  xlabel('wavenumber cm^{-1}');ylabel('AIRS - CrIS (K)');
  title(h1,'2018Jand021e048 A:C SNO std.err vs FOV 3 sets')
%saveas(gcf,[phome '2018d021e048_ac_sno_stderr_vs_fov_ac1_ac2t1_ac2ref_mw.png'],'png')
%}  

%{
% ---------------- choose hot subset (or no subset here)
 idx = ':';  % idx = uHot305;
 junk = squeeze(nbr_cbt(4,idx,:));
 dmn4 = dmn_btLW(4,idx);
 clear diff4;  diff4 = zeros(length(dmn4),4);
 for i=1:length(dmn4) diff4(i,:) = junk(i,:) - dmn4(i); end
clear junk; junk = reshape(diff4,[],4*length(dmn4));
xbins = [-40:0.2:40];  xcens = [-39.9:0.2:39.9];
pdf_diff4 = histcounts(junk, xbins);
pdf_nbr1  = histcounts(nbr_cbt(4,:,:),  btbins);
pdf_nbr2  = histcounts(nbr_cbt(4,uHot290,:),  btbins);
pdf_nbr3  = histcounts(nbr_cbt(4,uHot305,:),  btbins);
pdf_sno   = histcounts(cbt(4,:),  btbins);
pdf_sno2  = histcounts(cbt(4,uHot290), btbins);
pdf_sno3  = histcounts(cbt(4,uHot305), btbins);
 
clear pdf_*
%}
% -------------------------- quantiles --------------------------- %
if(strcmp(band,'LW')) ich = find(fc > 900,1); end % LW(713) = 402;   % or 16
if(strcmp(band,'MW')) ich = find(fc > 1231,1); end % MW 16
title5 = ['ASL AC.' num2str(src) ' SNO ' r.sdate ' to ' r.edate ' Quantiles ' wvn ' wn Bias'];
fh5=figure(5);clf;set(fh5,'Resize','Off');
  set(fh5,'Position',fh5.Position+[0 0 240 0]);
  h1=subplot(221);plot(r.q.qn(ich,1:end-1), r.q.btbias(ich,:), '.-');grid on;
  axis([190 330 -1 1]); ylabel('AIRS - CrIS K')
  h2=subplot(223);semilogy(r.q.qn(ich,1:end-1), r.q.binsz(ich,:),'-');grid on;xlim([190 330]);
  xlabel('Scene BT at 902 wn (K)');ylabel('population');
    linkaxes([h1 h2],'x');set(h1,'xticklabel','');
    pp1=get(h1,'position');set(h1,'position',[pp1(1) pp1(2)-pp1(4)*0.1 pp1(3) pp1(4)*1.1])
    pp2=get(h2,'position');set(h2,'position',[pp2(1) pp2(2)+pp2(4)*0.1 pp2(3) pp2(4)*1.1])  

% --- quantiles subset by FOV  -------
  h1=subplot(222); hold on;
  for i=1:9 
    plot(r.fov(i).qn(ich,1:end-1),r.fov(i).btbias(ich,:),'.-','color',cc(i,:)); 
  end
  grid on;axis([190 320 -1.3 1.5]);
  hleg = legend({'1','2','3','4','5','6','7','8','9'},'orientation','vertical',... %'Location','north',,...
     'Position',[0.9176 0.3373 0.0625 0.3833]);
  h2=subplot(224);hold on;
  for i=1:9 semilogy(r.fov(1).qn(ich,1:end-1), r.fov(i).binsz(ich,:),'.-');end
  grid on;xlim([190 320]); legend('bin population')
    linkaxes([h1 h2],'x');set(h1,'xticklabel','');
    pp1=get(h1,'position');set(h1,'position',[pp1(1) pp1(2)-pp1(4)*0.1 pp1(3) pp1(4)*1.1])
    pp2=get(h2,'position');set(h2,'position',[pp2(1) pp2(2)+pp2(4)*0.1 pp2(3) pp2(4)*1.1])  
  annotation('textbox', [0 0.9 1 0.1], 'String', title5, 'fontSize',14,...
    'EdgeColor', 'none','HorizontalAlignment', 'center')
  %saveas(gcf,[phome 'quantiles'],'');



% ----------------- Hot Scene Investigation -----------------------
%{
figure(5);clf;simplemap(s.cLat(ig(uHot290)), s.cLon(ig(uHot290)), btbias(uHot290));
  figure(2);plot(dbtcens, pdf_hot290,'+-');grid on;  disp( num2str(nanmean(dbt(uHot290))) )
     disp( num2str(nanstd(dxm_btLW(4,uHot290))) )
figure(1);clf;simplemap(s.cLat(uHot305), s.cLon(uHot305), dbt(uHot305)');
  figure(2);plot(dbtcens, pdf_hot305,'+-');grid on;  disp( num2str(nanmean(dbt(uHot305))) )
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end here for now %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
  linkaxes([h1 h2],'x');set(h1,'xticklabel','');
  pp1=get(h1,'position');set(h1,'position',[pp1(1) pp1(2)-pp1(4)*0.1 pp1(3) pp1(4)*1.1])
  pp2=get(h2,'position');set(h2,'position',[pp2(1) pp2(2)+pp2(4)*0.1 pp2(3) pp2(4)*1.1])  
%}

%btm   = 0.5*(dbtm + cbtm);
%mdr   = 1E-3*(1./drdbt(fd,btm') );
%drse  = sqrt((a.gddrs.^2 + a.gcdrs.^2))/sqrt(sum(a.nSam));
%dbse  = mdr.*drse';
