%% Plot new amplituhedron chambers (no scaling) + export STLs
clear; clc; close all;

%% --- Vertices: [id, x, y, z] ---
% v2 corrected: y = 14/9, z = 0
D = [ ...
  0,  0,              0,                -28/11;          % v0
  1,  0,              724/973,          -1292/973;       % v1
  2,  0,              14/9,             0;               % v2  <-- fixed
  3,  0,              0,               -9/10;            % v3
  4,  0,              0,                0;               % v4
  5,  0,             -36/23,            0;               % v5
  6,  543/851,        0,               -2834/4255;       % v6
  7,  70/81,          0,                0;               % v7
  8,  3230/2523,     -5668/7569,        0;               % v8
  9,  27/11,          0,                0;               % v9
];

ids = D(:,1);      % 0..9
V   = D(:,2:4);    % 10 x 3

%% --- Chamber vertex sets (0-based labels -> 1-based indices) ---
chamber_ids = { ...
    [0 1 3 6]   + 1, ...   % Chamber 1
    [3 4 5 6 7 8] + 1, ... % Chamber 2
    [1 2 3 4 6 7] + 1, ... % Chamber 3
    [6 7 8 9]   + 1  ...   % Chamber 4
};

chamber_names  = {'chamber1','chamber2','chamber3','chamber4'};
chamber_colors = [ ...
    0.05 0.45 0.95;   % blue
    1.00 0.85 0.00;   % yellow
    0.85 0.15 0.15;   % red
    0.10 0.95 0.95];  % cyan

%% --- 3D plot (no scaling) ---
figure('Color','w'); hold on; grid on; axis equal vis3d;
xlabel('X'); ylabel('Y'); zlabel('Z');
title('New amplituhedron chambers (no scaling)');

% Plot all vertices as grey spheres
scatter3(V(:,1), V(:,2), V(:,3), 60, [0.4 0.4 0.4], 'filled');
for i = 1:numel(ids)
    text(V(i,1), V(i,2), V(i,3), sprintf('  %d', ids(i)), ...
        'Color',[0.2 0.2 0.2], 'FontSize',9);
end

% Plot each chamber as convex hull patch
for c = 1:numel(chamber_ids)
    idx = chamber_ids{c};
    P   = V(idx,:);                              % local vertices
    K   = convhull(P(:,1), P(:,2), P(:,3));      % triangle faces

    patch('Faces',K, 'Vertices',P, ...
          'FaceColor',chamber_colors(c,:), ...
          'FaceAlpha',0.5, ...
          'EdgeColor',chamber_colors(c,:)*0.5, ...
          'LineWidth',1.0, ...
          'DisplayName',chamber_names{c});
end

view(35,25);
camlight headlight; lighting gouraud;
legend('Location','northeastoutside');

%% --- STL export for each chamber (ASCII, no scaling) ---
outdir = pwd;
for c = 1:numel(chamber_ids)
    idx = chamber_ids{c};
    P   = V(idx,:);
    K   = convhull(P(:,1), P(:,2), P(:,3));

    fname = fullfile(outdir, sprintf('%s_raw.stl', chamber_names{c}));
    write_stl_ascii(fname, P, K, chamber_names{c});
    fprintf('Wrote %s with %d triangles\n', fname, size(K,1));
end

%% --- Helper: simple ASCII STL writer ---
function write_stl_ascii(filename, V, F, solidname)
    if nargin < 4 || isempty(solidname)
        solidname = 'mesh';
    end
    fid = fopen(filename,'w');
    if fid==-1, error('Cannot open %s for writing.', filename); end
    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

    fprintf(fid,'solid %s\n', solidname);
    for i = 1:size(F,1)
        a = V(F(i,1),:);
        b = V(F(i,2),:);
        c = V(F(i,3),:);
        n = cross(b-a, c-a);
        n = n / max(norm(n), eps);
        fprintf(fid,'  facet normal %.8e %.8e %.8e\n', n(1), n(2), n(3));
        fprintf(fid,'    outer loop\n');
        fprintf(fid,'      vertex %.14f %.14f %.14f\n', a(1), a(2), a(3));
        fprintf(fid,'      vertex %.14f %.14f %.14f\n', b(1), b(2), b(3));
        fprintf(fid,'      vertex %.14f %.14f %.14f\n', c(1), c(2), c(3));
        fprintf(fid,'    endloop\n');
        fprintf(fid,'  endfacet\n');
    end
    fprintf(fid,'endsolid %s\n', solidname);
end
