clc;
clear;
close all;
% Sample data for a 5 sided polygon
% [0 0] 
% [50 0]
% [100 50]
% [50 100] 
% [0 100];

n = input('Specify the number of sides of the polygon you want to analyse (only >=5 values will be accepted) : ');
while n < 5
    n = input('number of sides entered is less than 5 Please re-enter Carefully : ');
end

%Generating number of two column vectors to hold the coordinates
X = zeros(n, 1);
Y = zeros(n, 1);

%Taking the coordinates As input
pos=1;
while pos<=n
    coords = input(['Enter coordinates in the format [x y]: ', pos]);
    X(pos) = coords(1);
    Y(pos) = coords(2);
    pos=pos+1;
end

%Taking input for the youngs modulus and poisson's ration of the material 
E = input("Enter Young's Modulus of the material Used : "); 
V = input("Enter the Poisson's Ratio of the material used : ");



SideLength = sqrt(diff(X).^2 + diff(Y).^2); %Creates a vector of size n-1 containing the edge length of all the edges or the polygon

shortestSideLength = min(SideLength); %getting the smallest side length of the polygon


shape = polyshape({X}, {Y}); % creates a 2D polygonal shape using the vertices specified by the vectors X and Y


triangulatedObject= triangulation(shape); %creates a triangulation object based on the shape specified above
finiteElemGeoObject = fegeometry(triangulatedObject); % converts the triangulation object into a finite element geometry object
pdegplot(finiteElemGeoObject); % Plots the finiteElemGeoObject this pdegplot function is used for plotting geometric objects in the Partial Differential Equations Toolbox


%% Creating the model from the above geometry

FEmodel = femodel(AnalysisType="structuralStatic", Geometry=finiteElemGeoObject); %Creates the finite element model from the geometric object created above

FEmodel.MaterialProperties = materialProperties(YoungsModulus=E, PoissonsRatio=V);%defining the properties of youngs modulus and poissons Ratio
figure
pdegplot(FEmodel, "VertexLabels","on", "EdgeLabels","on"); %Plotting the FE model

%giving the user choice of load to be applied 
loadChoice = input("select the kind of load you want to apply [1: point load, 2: distributed load]: ");


%if point load selected the following algorithm runs
if loadChoice == 1
    n = input("Number of vertices on which load needs to be applied : ");
    disp("Give the vertices where load needs to be applied one by one as we prompt it n times")
    for i = 1:n
        vertexNumber = input("From the figure plotted before specify the vertex number where load needs be applied: ");
        loadAmount = input(['Enter loads in format [Fx Fy]: ', i]);
        FEmodel.VertexLoad(vertexNumber) = vertexLoad(Force=loadAmount); %Loading the FE model with the point load
    end
else
    %Repeating the same for edge load
    n = input("Number of edges on which load needs to be applied : ");
    disp("Give the edge number where load needs to be applied one by one as we prompt it n times")
    for i = 1:n
        vertexNumber = input("enter edge number: ");
        pressure = input("Enter pressure normal to the boundary");
        FEmodel.EdgeLoad(vertexNumber) = edgeLoad(Pressure = pressure);
    end
end


%Setting up the boundary condition 
edges = input('Enter Edge numbers that needs to be fixed [1, 2, 3...]: ');
FEmodel.EdgeBC(edges) = edgeBC(Constraint="fixed");


FEmodel = generateMesh(FEmodel, Hmax=shortestSideLength/3);

figure
pdemesh(FEmodel);

%% solving and plotting


result = solve(FEmodel);


figure
pdeplot(result.Mesh, ...
        Deformation=result.Displacement )
title("Deformation")
axis equal;

figure
pdeplot(result.Mesh, ...
        XYData=result.VonMisesStress, ...
        ColorMap="jet")
title("VonMisesStress")
axis equal;
