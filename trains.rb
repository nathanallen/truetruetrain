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

  def self.distance_between(station_name, next_station_name)
    lookup[station_name].distance_to(next_station_name)
    rescue
      "NO SUCH ROUTE" 
  end

  def self.distance_along_route(*station_names)
    distance = 0
    stops = station_names.length-1
    stops.times do |i|
      distance += distance_between(*station_names[i..i+1])
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
    limits = set_limits(*opts)
    seed_connections = seed_station.connections.values
    seed_connections.map do |connection|
      route = Route.new(connection)
      depth_first_search(route, destination, *limits)
    end.flatten.compact
  end

  def depth_first_search(route, final_destination, *limits)
    connections = DirectoryModel.lookup[route.terminus].connections.values
    connections.map do |next_connection|
      new_fork = route.new_fork!(next_connection)
      evaluate_result(new_fork, final_destination, *limits)
    end
  end

  def evaluate_result(route, final_destination, max, min)
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

#Model

class Station
  attr_accessor :connections, :station_name

  def initialize(name, *connections)
    @station_name = name
    @connections = {}
    add_connections(connections)
  end

  def add_connections(connections)
    connections.each{|c| add_connection(c)}
  end

  def add_connection(connection)
    connections[connection.destination] = connection
  end

  def distance_to(station_name)
    connections[station_name].distance
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

class Route
  attr_accessor :distance, :connections

  def initialize(*connections)
    @connections = connections.flatten
    @distance = calculate_distance
  end

  def calculate_distance
    connections.map{|c| c.distance }.inject(:+)
  end

  def origin
    connections.first.origin
  end

  def destination
    connections.last.destination
  end

  alias_method :terminus, :destination

  def stops
    @connections.count
  end

  def new_fork!(next_connections)
    self.class.new_fork(self, next_connections)
  end

  def self.new_fork(route, next_connections)
    new_connections = route.connections, next_connections
    self.new(new_connections)
  end

end

class Directory

end

## Driver Code
test_file = ARGV[0] || 'test_input.txt'
test_input = File.read(test_file).split(', ')

DirectoryModel.new(test_input)
c = DirectorySearchHelper.new

## sanity check
p "#1: #{c.distance_along_route('A','B','C') == 9}"
p "#2: #{c.distance_along_route('A','D') == 5}"
p "#3: #{c.distance_along_route('A','D','C') == 13}"
p "#4: #{c.distance_along_route('A','E','B','C','D') == 22}"
p "#5: #{c.distance_along_route('A','E','D') == 'NO SUCH ROUTE'}"
p "#6: #{c.total_routes_between('C','C',3) == 2}"
p "#7: #{c.total_routes_between('A','C',4,4) == 3}"
p "#8: #{c.shortest_distance_between('A','C') == 9}"
p "#9: #{c.shortest_distance_between('B','B') == 9}"
p "#10: #{c.total_routes_by_limit_distance('C','C',30) == 7}"