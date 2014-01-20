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
  
  def distance_between(*args) #
    DirectoryModel.distance_between(*args)
  end

  def total_routes_between(*args)
    routes_between(*args).count
  end

  def distance_along_route(*stations) #
    DirectoryModel.distance_along_route(*stations) 
  end

  def routes_between(origin, destination, *opts)
    find_routes(origin, destination, *opts)
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

  private

  def find_routes(origin, destination, *opts)
    seed_route = Route.new(origin)
    bounds = set_limits(*opts)
    depth_first_search(seed_route, destination, *bounds)
  end

  def depth_first_search(route, final_destination, max, min)
    route.connections.map do |next_stop|
      new_fork = route.new_fork!(next_stop)
      evaluate_route(new_fork, final_destination, max, min)
    end.flatten.compact
  end

  def evaluate_route(route, final_destination, max, min)
    stops = route.stops.count      
    if route.destination == final_destination && stops >= min
      route
    elsif stops < max
      depth_first_search(route, final_destination, max, min)
    end
  end

  def find_all_recombinations(routes, limit)
    unique_routes = Set.new(routes.map{|route| route.stops})
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
      new_route = Route.new_splice(left_side, right_side)
      new_route if unique_routes.add?(new_route.stops)
    end
  end

  def set_limits(*opts)
    case opts.length
    when 2
      max = opts[0] + 1
      min = opts[1] + 1
    when 1
      max = opts[0] + 1
      min = 0
    when 0
      max = DirectoryModel.number_of_stations + 1
      min = 0
    end

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
  attr_accessor :stops, :distance

  def initialize(stops, distance=0)
    @distance = distance
    @stops = *stops
  end

  def origin
    stops.first
  end

  def destination
    stops.last
  end

  def connections #connecting_stations
    DirectoryModel.connections_from(last_stop)
  end

  alias_method :last_stop, :destination

  def new_fork!(next_stop)
    self.class.new_fork(self, next_stop)
  end

  def self.new_fork(route, next_stop)
    new_stops = *route.stops, next_stop
    next_distance = DirectoryModel.distance_between(route.last_stop, next_stop)
    new_distance = route.distance + next_distance
    self.new(new_stops, new_distance)
  end

  def self.new_splice(left_route, right_route) #check for valid route?
    new_stops = splice_together(left_route.stops, right_route.stops)
    new_distance = left_route.distance + right_route.distance
    self.new(new_stops, new_distance)
  end

  private

  def self.splice_together(left_stops, right_stops)
    left_stops + right_stops[1..-1]
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