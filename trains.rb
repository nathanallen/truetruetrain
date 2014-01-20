require 'set'

## Controller

class Main

  def initialize(graph_strings)
    load_graph(graph_strings)
  end
  
  def build_stations(origin_name, destination_name, distance)
    new_connection = Connection.new(origin_name, destination_name, distance)
    station = Station.find(origin_name)
    station ? station.add_connection(new_connection) : Station.new(origin_name, new_connection)
  end

  private

  def load_graph(graph_strings)
    graph_strings.each do |route_string|
      build_stations(route_string[0], route_string[1], route_string[2].to_i)
    end
  end

end

class SearchController < Main

  def routes_between(origin, destination, *opts)
    origin_station = Station.find(origin)
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
    Station.find(station_name).distance_to(next_station_name)
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
    connections = Station.connections_from(route.terminus)
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
    max_stops = opts[0] || Station.all.count + 1
    min_stops = opts[1] || 0
    [max_stops, min_stops]
  end

end

## Models

class Station
  attr_reader :connections_hash, :station_name

  @@stations = {}

  def initialize(name, *connections)
    @station_name = name
    @connections_hash = {}
    update_records(connections)
  end

  def self.find(station_name)
    @@stations[station_name]
  end

  def self.connections_from(station_name)
    find(station_name).connections
  end

  def self.all
    @@stations
  end

  def add_connection(new_connection)
    connections_hash[new_connection.destination] = new_connection
  end

  def distance_to(station_name)
    connections_hash[station_name].distance
  end

  def connection_names
    connections_hash.keys
  end

  def connections
    connections_hash.values
  end

  private

  def update_records(new_connections)
    add_connections(new_connections)
    add_station
  end

  def add_connections(new_connections)
    new_connections.each{|c| add_connection(c)}
  end

  def add_station
    @@stations[self.station_name] = self
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

  def initialize(connections)
    @connections = *connections
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
    connections.count
  end

  def new_fork!(next_connections)
    self.class.new_fork(self, next_connections)
  end

  def self.new_fork(route, next_connections)
    new_connections = [route.connections, next_connections].flatten
    self.new(new_connections)
  end

  private

  def total_distance
    connections.inject(0){|memo,c| memo += c.distance}
  end

end

## Driver Code
test_file = ARGV[0] || 'test_input.txt'
test_input = File.read(test_file).split(', ')
s = SearchController.new(test_input)

## Sanity Check
p "#1: #{s.distance_along_route('A','B','C') == 9}"
p "#2: #{s.distance_along_route('A','D') == 5}"
p "#3: #{s.distance_along_route('A','D','C') == 13}"
p "#4: #{s.distance_along_route('A','E','B','C','D') == 22}"
p "#5: #{s.distance_along_route('A','E','D') == 'NO SUCH ROUTE'}"
p "#6: #{s.total_routes_between('C','C',3) == 2}"
p "#7: #{s.total_routes_between('A','C',4,4) == 3}"
p "#8: #{s.shortest_distance_between('A','C') == 9}"
p "#9: #{s.shortest_distance_between('B','B') == 9}"
p "#10: #{s.total_routes_by_limit_distance('C','C',30) == 7}"