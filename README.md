##TrueTrueTrain
TrueTrueTrain is a ruby application that loads a graph describing a network of stations, connections and routes. Various queries can then be performed against the data to find information about the routes, for instance: the distance along a certain route, the number of different routes between two towns, the shortest route between two towns.

As much as possible I have tried to follow Sandi Metz's rules of modularity, among them, trying to write single-responsibility methods of 5 lines or less.

An OO approach was used, classes include:
* Station: An origin point or node. Stations contain their Connections, and can be queried for connecting information. 
* Connection: A line between two Stations, and its distance.
* Route: A series of Connections.

The test input, and expected output, provided with the challenge were used as the basis for some simple tests.

To run the program, on the command line run:
```
ruby truetruetrain.rb [test_input.txt]
```
Optionally, you may supply your own test input file (by default it will load test_input.txt).

Given more time I would like to focus on the high-level organization of the code, specifically I would like to use the metaphor of a Directory to encompass the various classes and their behaviors.



###Problem Description: Trains
 
Input:  A directed graph where a node represents a town and an edge represents a route between two towns.  The weighting of the edge represents the distance between the two towns.  A given route will never appear more than once, and for a given route, the starting and ending town will not be the same town.
 
Output: For test input 1 through 5, if no such route exists, output 'NO SUCH ROUTE'.  Otherwise, follow the route as given; do not make any extra stops!  For example, the first problem means to start at city A, then travel directly to city B (a distance of 5), then directly to city C (a distance of 4).
 
1. The distance of the route A-B-C.
2. The distance of the route A-D.
3. The distance of the route A-D-C.
4. The distance of the route A-E-B-C-D.
5. The distance of the route A-E-D.
6. The number of trips starting at C and ending at C with a maximum of 3 stops.  In the sample data below, there are two such trips: C-D-C (2 stops). and C-E-B-C (3 stops).
7. The number of trips starting at A and ending at C with exactly 4 stops.  In the sample data below, there are three such trips: A to C (via B,C,D); A to C (via D,C,D); and A to C (via D,E,B).
8. The length of the shortest route (in terms of distance to travel) from A to C.
9. The length of the shortest route (in terms of distance to travel) from B to B.
10. The number of different routes from C to C with a distance of less than 30.  In the sample data, the trips are: CDC, CEBC, CEBCDC, CDCEBC, CDEBC, CEBCEBC, CEBCEBCEBC.
 
####Test Input:
 
For the test input, the towns are named using the first few letters of the alphabet from A to E.  A route between two towns (A to B) with a distance of 5 is represented as AB5.
 
Graph: AB5, BC4, CD8, DC8, DE6, AD5, CE2, EB3, AE7
 
Expected Output:
 
* Output #1: 9
* Output #2: 5
* Output #3: 13
* Output #4: 22
* Output #5: NO SUCH ROUTE
* Output #6: 2
* Output #7: 3
* Output #8: 9
* Output #9: 9
* Output #10: 7