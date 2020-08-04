% CrIS Neighbour look-up table

% Four Nearest Neighbours for nadir subset
%
%        X
%     X  O  X
%        X
%
% [dATR FOR FOV  dATR FOR FOV  dATR FOR FOV  dATR FOR FOV]

cFOR(16).d{1} = [0 16 2;  0 15 3;   0 16 4; -1 16 7];
cFOR(16).d{2} = [0 16 3;  0 16 1;   0 16 5; -1 16 8];
cFOR(16).d{3} = [0 17 1;  0 16 2;   0 16 6; -1 16 9];
cFOR(16).d{4} = [0 16 5;  0 15 6;   0 16 7;  0 16 1];
cFOR(16).d{5} = [0 16 6;  0 16 4;   0 16 8;  0 16 2];
cFOR(16).d{6} = [0 17 4;  0 16 5;   0 16 9;  0 16 3];
cFOR(16).d{7} = [0 16 8;  0 15 9;   1 16 1;  0 16 4];
cFOR(16).d{8} = [0 16 9;  0 16 7;   1 16 2;  0 16 5];
cFOR(16).d{9} = [0 17 7;  0 16 8;   1 16 3;  0 16 6];

cFOR(15).d{1} = [0 15 2;  0 14 3;   0 15 4; -1 15 7];
cFOR(15).d{2} = [0 15 3;  0 15 1;   0 15 5; -1 15 8];
cFOR(15).d{3} = [0 16 1;  0 15 2;   0 15 6; -1 15 9];
cFOR(15).d{4} = [0 15 5;  0 14 6;   0 15 7;  0 15 1];
cFOR(15).d{5} = [0 15 6;  0 15 4;   0 15 8;  0 15 2];
cFOR(15).d{6} = [0 16 4;  0 15 5;   0 15 9;  0 15 3];
cFOR(15).d{7} = [0 15 8;  0 14 9;   1 15 1;  0 15 4];
cFOR(15).d{8} = [0 15 9;  0 15 7;   1 15 2;  0 15 5];
cFOR(15).d{9} = [0 16 7;  0 15 8;   1 15 3;  0 15 6];

% FOR = 15. CIFOV = 1, first nearest: (Atrack offset,  FOR, CIFOV)
% cFOR(15).d{1}(1,:) =  0    15     2
