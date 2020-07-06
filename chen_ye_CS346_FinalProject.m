%{
Jiahao (Derek) Ye
Jiyao (Lukas) Chen
2020 Spring CS346
Final Project
chen_ye_CS346_FinalProject.m
%}

% initialize simulation constants
N = 50;                      % # of iterations (total simulation steps)
country_simulate = 'Brazil';  % the country we are simulating
% constants for initalizing the grid
size = 50;                   % # of rows and columns
prob_tree = 0.9;             % probability that a cell has a tree
prob_burning = 0.03;         % probability that the tree is burning
prob_lightning = 0;          % probability of being hit by lightning
prob_rain_putout = 0.1;      % probability of rainstorm putting out a fire
% a list of possible global weathers
weathers = ["wind"];

% a map of country names and their responsiveness index
countryNames = {'Australia', 'Brazil', 'Spain', 'Ukraine', 'US'};
responsiveness = [0.4, 0.6, 0.35, 0.3, 0.5];
countryIdx = containers.Map(countryNames,responsiveness);

global empty_val        
empty_val = 0;              % cell value | 0: empty
global poor_tree_val  
poor_tree_val = 2;          % cell value | 2: poorly flammable tree
global med_tree_val   
med_tree_val = 3;           % cell value | 3: medium flammable tree
global high_tree_val 
high_tree_val = 5;          % cell value | 5: highly flammable tree
global burn_val      
burn_val = 6;               % cell value | 6: burning
global burnDown_val   
burnDown_val = 9;           % cell value | 9: burnt tree (burned down)
global ash_val;   
ash_val = 7;                % cell value | 7: fire being put out
global ff_val;   
ff_val = 10;                % cell value | 10: firefighter

x_inds = 1:size;     % grid indices
y_inds = 1:size;     % grid indices
grid = initForest(size, prob_tree, prob_burning);   % simulation grid
ext_grid = zeros(size+2,size+2);                    % extended grid
ext_grid(x_inds+1,y_inds+1) = grid(x_inds,y_inds);  % update extended grid
gridList{1} = grid;                 % initialize frame list
extGridList{1} = ext_grid;          % initialize frame list

% create a reference frame
% refExtGrid: reference extended grid storing initial cell information
%             used for restoring the cell information
refExtGrid = extGridList{1};
for i = 2:size
      for j = 2:size
          if refExtGrid(i,j) == burn_val
              refExtGrid(i,j) = ash_val;
          end
      end
end

% run simulation
for i = 2:N
    % retreive grid in the previous itereation
    grid_0 = gridList{i-1};
    extGrid_0 = extGridList{i-1};
    
    % randomly select current weather every 2 iteration
    if mod(i,2)==0
        weather = weathers(randi(length(weathers)));
        weather_list(i) = weather;
    else
        weather_list(i) = weather_list(i-1);
    end
    
    % once gov intervention begins
    if i == 1 + int8(countryIdx(country_simulate)*10)
        % initialize firefighters at the left-most col
        grid_0(1:size,1) = ff_val;
        % update corresponding extended grid
        extGrid_0(x_inds+1,y_inds+1) = grid_0(x_inds,y_inds);
    end
    
   % create a temp reference grid to check
   % if the curr firefigher has already moved in this iteration
   ffPosRef_extGrid = extGrid_0;
    for x = 1:size
        for y = 1:size
            % update individual firefigher pos/status
            [extGrid_0, refExtGrid] = ff_move(extGrid_0,...
                   ffPosRef_extGrid,refExtGrid, x+1, y+1);
            % update other indivual cell status
            [grid_0(x,y), refExtGrid] = spread(extGrid_0,x+1,y+1,...
                    prob_lightning,prob_rain_putout, weather, refExtGrid);
            % update the exnteded grid
            extGrid_0(x+1,y+1) = grid_0(x,y);
        end
    end
    
    % keep track of each iteration
    gridList{i} = grid_0;
    extGridList{i} = extGrid_0;
end

% visualise simulation
show_CA_List(gridList,1, weather_list);

% parameters | n: # of cells each row/col
%            | probTree: prob that a cell contains a tree
%            | probBurning: prob that a tree is burning
% returns    | a nxn grid with initialized forest
% initialize a nxn grid 
% each cell is initialized to be based on the parameters given
function grid = initForest(n, probTree, probBurning)
    global empty_val
    global poor_tree_val
    global med_tree_val
    global high_tree_val
    global burn_val
    
    % create a tree type list
    allTree_vals = [poor_tree_val, med_tree_val, high_tree_val,...
        med_tree_val, high_tree_val, med_tree_val];
    
    grid = zeros(n,n);      % initialize a n*n gird
    
    % fill in trees/burning trees based on prob
    for i = 1:n
        for j = 1:n
            if rand() < probTree        % if curr cell should have a tree
                if rand() < probBurning     % if the tree should be burning
                    grid(i,j) = burn_val;       % set to burn
                else
                    grid(i,j) = allTree_vals...
                        (randi(length(allTree_vals))); % set a tree
                end
            else
                grid(i,j) = empty_val;     % otherwise, no tree/empty
            end
        end
    end
end

% parameters | extGrid: extended grid of the simulation grid
%            | x: x coordinate
%            | y: y coordinate
%            | probLightning: prob of lightning
%            | weather: global weather
%            | refExtGrid: reference grid
% returns    | new_value: curr cell's updated value based on rules
%            | refExtGrid: updated reference grid
% update curr cell's status based on 
% its neighboring cells in the given extendedGrid
function [new_value, refExtGrid] = spread(extGrid, x, y,probLightning,...
                                     prob_rain_putout, weather, refExtGrid)
    % initialize the global variables
    global empty_val;
    global poor_tree_val;
    global med_tree_val;
    global high_tree_val;
    global burn_val;
    global burnDown_val;
    global ash_val;
    global ff_val;
    
    if extGrid(x,y) == ff_val
        new_value = ff_val;
    else
        if extGrid(x,y) == empty_val            % no tree
            if weather == "lightning" && rand() < probLightning
                new_value = burn_val;
            else
                new_value = extGrid(x,y);
            end
        elseif extGrid(x,y) == burnDown_val     % completely burnt out
            new_value = extGrid(x,y);
        elseif extGrid(x,y) == burn_val         % burning
            if weather == "drizzle"
                new_value = extGrid(x,y);
            elseif weather == "rainstorm" && rand() < prob_rain_putout
                new_value = ash_val;
                refExtGrid(x,y) = burnDown_val;
            else
                new_value = burnDown_val;
                refExtGrid(x,y) = burnDown_val;
            end
        elseif extGrid(x,y) == ash_val
            new_value = extGrid(x,y);
        else
            % create a list of all neighbors
            list_of_neighbors = [extGrid(x-1, y-1), extGrid(x-1, y),...
                extGrid(x-1, y+1), extGrid(x, y-1), extGrid(x, y),...
                extGrid(x, y+1), extGrid(x+1, y-1), extGrid(x+1, y),...
                extGrid(x+1, y+1)];
            % count the number of neighboring burning trees
            num_burning_tree = length(list_of_neighbors(...
                                            list_of_neighbors==burn_val));

            % update num_burning_tree based on the current weather
            if weather == "wind" && num_burning_tree ~= 0
                num_burning_tree = num_burning_tree + 2;
            end
            if weather == "drizzle" && num_burning_tree >= 1
                num_burning_tree = num_burning_tree - 1;
            elseif weather == "rainstorm"
                num_burning_tree = num_burning_tree / 2;
            end

            % rule: tree value + neighbor burning # >= 6 makes a tree burn
            if extGrid(x,y) + num_burning_tree >= burn_val
                % update the current tree to be burning
                if extGrid(x,y-1) == ff_val
                    new_value = extGrid(x,y);
                elseif extGrid(x,y) == poor_tree_val
                    new_value = med_tree_val;
                elseif extGrid(x,y) == med_tree_val
                    new_value = high_tree_val;
                else
                    new_value = burn_val;
                end
            else
                % maintain current status
                new_value = extGrid(x,y);
            end        
        end
    end
end

% parameters | extGrid: extended grid of the simulation grid
%            | ffPrevPosGrid: reference extended grid for firefighter's
%                             position at the previous iteration
%            | refExtGrid: reference extended grid storing initial cells
%            | x: x coordinate
%            | y: y coordinate
% returns    | new_extGrid: curr cell's updated value based on rules
%            | refExtGrid: updated reference grid
% given the firefighter's curr pos, and previous pos
%   1) decide whether the firefighter is going to move rightward or stay
%   2) extinguish fire
function [new_extGrid, refExtGrid] = ff_move(extGrid,ffPrevPosGrid,...
                                                        refExtGrid, x, y)
    global ff_val
    global empty_val
    global poor_tree_val
    global med_tree_val
    global high_tree_val
    global burn_val
    global burnDown_val
    global ash_val
    
    % if curr pos is a firefighter
    if extGrid(x,y) == ff_val
        % if the right tree is burning
        if extGrid(x,y+1) == burn_val
            extGrid(x,y+1) = ash_val;               % turn the fire down
            refExtGrid(x,y+1) = ash_val;           % memorize it
        % otherwise, move to the next right position if can
        elseif extGrid(x,y+1) == empty_val...
                || extGrid(x,y+1) == burnDown_val...
                || extGrid(x,y+1) == poor_tree_val ...
                || extGrid(x,y+1) == med_tree_val ...
                || extGrid(x,y+1) == high_tree_val ...
                || extGrid(x,y+1) == ash_val
            % if the ff has already moved
            if ffPrevPosGrid(x,y-1) == ff_val
                extGrid(x,y) = extGrid(x,y);      % maintain curr position
            % otherwise, move
            elseif extGrid(x,y+1) == ash_val
                % if the next right one is ash, memorize it because we need
                % to restore the ash value after firefighters leave
                refExtGrid(x,y+1) = ash_val;
                extGrid(x,y+1) = ff_val;          % move
                % restore curr position's feature
                extGrid(x,y) = refExtGrid(x,y);
            else
                % if the next right one is not ash
                extGrid(x,y+1) = ff_val;          % simply move
                % restore curr position's feature
                extGrid(x,y) = refExtGrid(x,y);
            end            
        else
            extGrid(x,y) = extGrid(x,y);          % firefigher is stuck here
        end
        new_extGrid = extGrid;                    % update the grid
    else
        new_extGrid = extGrid;                    % update the grid
    end
end

% parameters | gridlist: frames of iterations
%            | interval: number of interval
%            | weather_list: each frame's corresponding weather condition
% returns    none
% draw simulation results for every (interval) iteration
function show_CA_List(gridlist,interval, weather_list)
%   set customized colormap
    cmap = [1 1 1; 0.1 0.9 0.1; 0.1 0.7 0.3;... % no tree; poor; medium; 
        0.1 0.4 0.1; 0.9 0 0; 0.6 0.6 0.6;...   %  highly; fire; ash; 
        0.1 0.1 0; 0.1 0.8 0.8];                % burned down; firefighter
    colormap(cmap);
    % draw graph for every (inverval) iteration
    for i = 1:interval:length(gridlist)
        data = gridlist{i};
        imagesc(data); 
        % set colormap scale to represent the cell in the way we want
        caxis([0 11]); 
        colorbar; 
        title(['Frame:', i, 'Weather: ', weather_list(i)]); 
        hold;
        axis equal; axis tight; axis xy;
        
        fprintf('press any key for next frame...\n'); 
        waitforbuttonpress;
    end
end