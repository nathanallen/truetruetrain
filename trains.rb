require 'set'

class DirectoryModel

  def initialize(graph)
    graph.each do |route|
      DirectoryModel.load(route[0], route[1], route[2].to_i) #
    end
  end

  def self.lookup
    @lookup ||= {}
  end
  
  def self.load(origin, destination, distance)
    connection = Connection.new(origin, destination, distance)
    if lookup[origin]
      lookup[origin].add_connection(connection)
    else
      lookup[origin] = Station.new(origin, connection)
    end
  end

  def self.distance_between(station, next_station)
    lookup[station].distance_to(next_station)
    rescue
      "NO SUCH ROUTE" 
  end

  def self.distance_along_route(*stations)
    distance = 0
    stops = stations.length-1
    stops.times do |i|
      distance += distance_between(*stations[i..i+1])
    end
    distance
    
    rescue TypeError
      "NO SUCH ROUTE" 
  end

  def self.number_of_stations
    lookup.count
  end

  def self.connections_from(stop)
    lookup[stop].connections.keys
  end

end


class DirectorySearchHelper

  def routes_between(origin, destination, *opts)
    origin_station = DirectoryModel.lookup[origin]
    find_routes(origin_station, destination, *opts)
  end

  def total_routes_between(*args)
    routes_between(*args).count
  end
  
  def routes_by_distance(origin, destination)
    routes = routes_between(origin, destination)
    routes.sort_by!{|route| route.distance}
  end

  def shortest_distance_between(*args)
    routes_by_distance(*args).first.distance
  end

  def routes_by_limit_distance(origin, destination, limit)
    routes = routes_between(origin, destination)
    find_all_recombinations(routes, limit)
  end

  def total_routes_by_limit_distance(origin, destination, distance)
    routes_by_limit_distance(origin, destination, distance).count
  end

  def distance_between(*args) #
    DirectoryModel.distance_between(*args)
  end

  def distance_along_route(*stops) #
    DirectoryModel.distance_along_route(*stops) 
  end

  private

  def find_routes(seed_station, destination, *opts)
    #seed_route = Route.new(seed_station)
    connections = seed_station.connections.values
    bounds = set_limits(*opts)
    
    connections.map do |next_connection|
      route = Route.new(next_connection)
      depth_first_search(route, destination, *bounds)
    end.flatten.compact
  end

  def depth_first_search(route, final_destination, max, min)
    route.future_connections.map do |next_connection|
      new_fork = route.new_fork!(next_connection)
      evaluate_route(new_fork, final_destination, max, min)
    end.flatten.compact
  end

  def evaluate_route(route, final_destination, max, min)
    stops = route.stops    
    if route.destination == final_destination && stops >= min #
      route
    elsif stops < max
      depth_first_search(route, final_destination, max, min)
    end
  end

  def find_all_recombinations(routes, limit)
    unique_routes = Set.new(routes.map{|route| route.connections})
    routes.each do |left_side|
      routes.each do |right_side|
        combo_route = evaluate_combo(left_side, right_side, limit, unique_routes)
        routes << combo_route if combo_route
      end
    end
  end

  def evaluate_combo(left_side, right_side, limit, unique_routes)
    total_dist = left_side.distance + right_side.distance
    if total_dist < limit
      new_route = left_side.new_fork!(right_side.connections)
      new_route if unique_routes.add?(new_route.connections)
    end
  end

  def set_limits(*opts)
    max = opts[0] || DirectoryModel.number_of_stations + 1
    min = opts[1] || 0
    [max, min]
  end

end

class Connection
  attr_reader :origin, :destination, :distance

  def initialize(origin, destination, distance)
    @origin = origin
    @destination = destination
    @distance = distance
  end

end

class Station
  attr_accessor :connections, :station

  def initialize(station, *connections)
    @station = station
    @connections = {}
    add_connections(connections)
  end

  def add_connections(connections)
    connections.each{|c| add_connection(c)}
  end

  def add_connection(connection)
    connections[connection.destination] = connection
  end

  def distance_to(station)
    connections[station].distance
  end

end

class Route
  attr_accessor :distance, :connections, :last_station

  def initialize(*connections)
    @connections = connections.flatten
    @distance = calculate_distance
    #@last_station = terminal_station
  end

  def calculate_distance
    connections.map{|c| c.distance }.inject(:+)
  end

  def origin
    connections.first ? connections.first.origin : last_station.station
  end

  def destination
    connections.last ? connections.last.destination : last_station.station
  end

  def stops
    @connections.count
  end

  def future_connections #connecting_stations
    DirectoryModel.lookup[destination].connections.values #
  end

  def new_fork!(next_connections)
    self.class.new_fork(self, next_connections)
  end

  def self.new_fork(route, next_connections)
    new_connections = route.connections, next_connections
    self.new(new_connections)
  end

end


## Driver Code
test_file = ARGV[0] || 'test_input.txt'
test_input = File.read(test_file).split(', ')

DirectoryModel.new(test_input)
c = DirectorySearchHelper.new

p "#1: #{c.distance_along_route('A','B','C') == 9}"
p "#2: #{c.distance_along_route('A','D') == 5}"
p "#3: #{c.distance_along_route('A','D','C') == 13}"
p "#4: #{c.distance_along_route('A','E','B','C','D') == 22}"
p "#5: #{c.distance_along_route('A','E','D') == 'NO SUCH ROUTE'}"

# 6. The number of routes_be starting at C and ending at C with a maximum of 3 stops.  In the sample data below, there are two such trips: C-D-C (2 stops). and C-E-B-C (3 stops).
# 7. The number of trips starting at A and ending at C with exactly 4 stops.  In the sample data below, there are three such trips: A to C (via B,C,D); A to C (via D,C,D); and A to C (via D,E,B).
p "#6: #{c.total_routes_between('C','C',3) == 2}"
p "#7: #{c.total_routes_between('A','C',4,4) == 3}"
#p "ABCDC, ADCDC, ADEBC"

# 8. The length of the shortest route (in terms of distance to travel) from A to C.
# 9. The length of the shortest route (in terms of distance to travel) from B to B.
p "#8: #{c.shortest_distance_between('A','C') == 9}"
p "#9: #{c.shortest_distance_between('B','B') == 9}"

# 10. The number of different routes from C to C with a distance of less than 30.  In the sample data, the trips are: CDC, CEBC, CEBCDC, CDCEBC, CDEBC, CEBCEBC, CEBCEBCEBC.
p "#10: #{c.total_routes_by_limit_distance('C','C',30) == 7}"
#p "CDC, CEBC, CEBCDC, CDCEBC, CDEBC, CEBCEBC, CEBCEBCEBC"