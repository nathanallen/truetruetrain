require 'set'

## Controller

class DirectoryControl

  @@stations = {}

  def initialize(graph_strings)
    load_graph(graph_strings)
  end
  
  def update_directory(origin_name, destination_name, distance)
    new_connection = Connection.new(origin_name, destination_name, distance)
    if @@stations[origin_name]
      @@stations[origin_name].add_connection(new_connection)
    else
      @@stations[origin_name] = Station.new(origin_name, new_connection)
    end
  end

  private

  def load_graph(graph_strings)
    graph_strings.each do |route_string|
      update_directory(route_string[0], route_string[1], route_string[2].to_i)
    end
  end

end

class DirectorySearch < DirectoryControl

  def lookup(station_name)
    @@stations[station_name]
  end

  def connections_from(station_name)
    lookup(station_name).connections
  end

  def routes_between(origin, destination, *opts)
    origin_station = lookup(origin)
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

  def distance_between(station_name, next_station_name)
    lookup(station_name).distance_to(next_station_name)
    rescue
      "NO SUCH ROUTE" 
  end

  def distance_along_route(*station_names)
    distance = 0
    stops = station_names.length-1
    stops.times do |i|
      distance += distance_between(*station_names[i..i+1])
    end
    distance
    
    rescue TypeError
      "NO SUCH ROUTE" 
  end

  def number_of_stations 
    @@stations.count
  end

  private

  def find_routes(seed_station, destination, *opts)
    limits = set_limits(*opts)
    seed_connections = seed_station.connections
    inititate_search(seed_connections, destination, *limits)
  end

  def inititate_search(seed_connections, destination, *limits)
    seed_connections.map do |connection|
      route = Route.new(connection)
      depth_first_search(route, destination, *limits)
    end.flatten.compact
  end

  def depth_first_search(route, final_destination, *limits)
    connections = connections_from(route.terminus)
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
    routes.each do |left_route|
      routes.each do |right_route|
        combo_route = evaluate_combo(left_route, right_route, limit, unique_routes)
        routes << combo_route if combo_route
      end
    end
  end

  def evaluate_combo(left_route, right_route, limit, unique_routes)
    total_dist = left_route.distance + right_route.distance
    if total_dist < limit
      new_route = left_route.new_fork!(right_route.connections)
      new_route if unique_routes.add?(new_route.connections)
    end
  end

  def set_limits(*opts)
    max = opts[0] || number_of_stations + 1
    min = opts[1] || 0
    [max, min]
  end

end

## Model

class Station
  attr_reader :connection_hash, :station_name

  def initialize(name, *connections)
    @station_name = name
    @connection_hash = {}
    add_connections(connections)
  end

  def add_connections(connections)
    connections.each{|c| add_connection(c)}
  end

  def add_connection(connection)
    connection_hash[connection.destination] = connection
  end

  def distance_to(station_name)
    connection_hash[station_name].distance
  end

  def connection_names
    connection_hash.keys
  end

  def connections
    connection_hash.values
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
  attr_reader :distance, :connections

  def initialize(*connections)
    @connections = connections.flatten
    @distance = total_distance
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

  private

  def total_distance
    connections.map{|c| c.distance }.inject(:+)
  end

end


## Driver Code
test_file = ARGV[0] || 'test_input.txt'
test_input = File.read(test_file).split(', ')
d = DirectorySearch.new(test_input)

## Sanity Check
p "#1: #{d.distance_along_route('A','B','C') == 9}"
p "#2: #{d.distance_along_route('A','D') == 5}"
p "#3: #{d.distance_along_route('A','D','C') == 13}"
p "#4: #{d.distance_along_route('A','E','B','C','D') == 22}"
p "#5: #{d.distance_along_route('A','E','D') == 'NO SUCH ROUTE'}"
p "#6: #{d.total_routes_between('C','C',3) == 2}"
p "#7: #{d.total_routes_between('A','C',4,4) == 3}"
p "#8: #{d.shortest_distance_between('A','C') == 9}"
p "#9: #{d.shortest_distance_between('B','B') == 9}"
p "#10: #{d.total_routes_by_limit_distance('C','C',30) == 7}"