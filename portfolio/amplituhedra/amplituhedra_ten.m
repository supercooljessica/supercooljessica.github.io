%% A6,3,1 Example 2.1: 10 chambers
%  - Vertices from Table on p.9 (Example 2.1)
%  - Chamber vertex sets from same page
%  - 3D plot of all chambers (overlapping)
%  - One binary STL per chamber

clear; clc; close all;

%% --- Vertices: i, x_i, y_i, z_i (from PDF, Example 2.1) ---
% Index i is 0-based in the paper; MATLAB uses 1-based, so we store as i+1.

V = [ ...
   0.000000   0.000000  -3.287491;  % 0
   0.000000   0.408189  -1.624123;  % 1
   0.000000   0.806748   0.000000;  % 2
   0.000000   1.095396   1.176239;  % 3
   0.000000   0.000000  -0.946371;  % 4
   0.000000   0.000000   0.000000;  % 5
   0.000000   0.000000   0.742036;  % 6
   0.000000  -0.569970   0.000000;  % 7
   0.000000  -0.820900   0.416641;  % 8
   0.000000  -1.871992   0.000000;  % 9
   0.283385   0.000000  -0.752756;  % 10
   0.367543   0.000000   0.000000;  % 11
   0.436168   0.000000   0.613814;  % 12
   0.528195  -0.352626   0.000000;  % 13
   0.641649  -0.516045   0.348853;  % 14
   0.912189  -1.195482   0.000000;  % 15
   1.385157   0.000000   0.000000;  % 16
   1.727805   0.000000   0.234105;  % 17
   2.524149   0.000000   0.000000;  % 18
   3.943741   1.052816   0.000000]; % 19

nVerts = size(V,1);

%% --- Chamber vertex sets (from Example 2.1, p.9) ---
% Paper uses 0-based labels; add 1 for MATLAB indices.

chambers = { ...
    struct('name','blue',    'ids',[0 1 4 10]          + 1), ...
    struct('name','yellow',  'ids',[4 5 7 10 11 13]    + 1), ...
    struct('name','red',     'ids',[1 2 4 5 10 11]     + 1), ...
    struct('name','cyan',    'ids',[10 11 13 16]       + 1), ...
    struct('name','olive',   'ids',[7 8 9 13 14 15]    + 1), ...
    struct('name','magenta', 'ids',[5 6 7 8 11 12 13 14]+1), ...
    struct('name','green',   'ids',[13 14 15 16 17 18] + 1), ...
    struct('name','teal',    'ids',[2 3 5 6 11 12]     + 1), ...
    struct('name','orange',  'ids',[11 12 13 14 16 17] + 1), ...
    struct('name','pink',    'ids',[16 17 18 19]       + 1) ...
};

% Rough RGB colors matching the figure
colorMap = struct( ...
    'blue',    [0.15 0.35 0.95], ...
    'yellow',  [1.00 0.90 0.10], ...
    'red',     [0.90 0.20 0.20], ...
    'cyan',    [0.10 0.90 0.95], ...
    'olive',   [0.55 0.65 0.25], ...
    'magenta', [0.80 0.20 0.70], ...
    'green',   [0.10 0.65 0.30], ...
    'teal',    [0.00 0.70 0.70], ...
    'orange',  [1.00 0.55 0.10], ...
    'pink',    [0.95 0.55 0.75]);

%% --- 3D plot of all chambers (overlaid, like Sage figure) ---
figure('Color','w'); hold on; grid on; axis equal vis3d;
xlabel('x'); ylabel('y'); zlabel('z');
title('A_{6,3,1} Example 2.1: 10 bounded chambers');

% plot all vertices as grey dots with labels
scatter3(V(:,1),V(:,2),V(:,3),25,[0.4 0.4 0.4],'filled','HandleVisibility','off');
for i = 1:nVerts
    text(V(i,1),V(i,2),V(i,3),sprintf(' %d',i-1), ...
        'FontSize',7,'Color',[0.2 0.2 0.2]);
end

for c = 1:numel(chambers)
    ch  = chambers{c};
    idx = ch.ids;
    P   = V(idx,:);
    % convex hull in 3D
    K   = convhull(P(:,1),P(:,2),P(:,3));
    col = colorMap.(ch.name);

    patch('Faces',K,'Vertices',P, ...
          'FaceColor',col, ...
          'FaceAlpha',0.7, ...
          'EdgeColor',[0 0 0], ...
          'LineWidth',0.6, ...
          'DisplayName',ch.name);
end

view(40,20);
camlight headlight; lighting gouraud;
legend('Location','northeastoutside');

%% --- Binary STL export: one file per chamber ---
outdir = pwd;
for c = 1:numel(chambers)
    ch  = chambers{c};
    idx = ch.ids;
    P   = V(idx,:);
    K   = convhull(P(:,1),P(:,2),P(:,3));

    fname = fullfile(outdir, sprintf('chamber_%s_example2_1.stl', ch.name));
    write_binary_stl(fname, P, K);
    fprintf('Wrote %s (%d triangles)\n', fname, size(K,1));
end

%% --- Helper: binary STL writer ---
function write_binary_stl(filename, V, F)
    fid = fopen(filename,'w','ieee-le');
    if fid==-1, error('Cannot open %s for writing.', filename); end
    cleaner = onCleanup(@() fclose(fid));

    % 80-byte header
    fwrite(fid, zeros(1,80,'uint8'), 'uint8');
    % triangle count
    fwrite(fid, uint32(size(F,1)), 'uint32');

    for i = 1:size(F,1)
        a = V(F(i,1),:);
        b = V(F(i,2),:);
        c = V(F(i,3),:);
        n = cross(b-a, c-a);
        nNorm = norm(n);
        if nNorm > 0
            n = n / nNorm;
        else
            n = [0 0 0];
        end
        fwrite(fid, single(n), 'float32');  % normal
        fwrite(fid, single(a), 'float32');  % vertex 1
        fwrite(fid, single(b), 'float32');  % vertex 2
        fwrite(fid, single(c), 'float32');  % vertex 3
        fwrite(fid, uint16(0), 'uint16');   % attribute byte count
    end
end
