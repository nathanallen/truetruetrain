require 'set'

class Control
  def initialize(graph)
    graph.each{|route| Directory.load(*route)}
  end
end

class Directory

  def self.lookup
    @lookup ||= Hash.new("NO SUCH ROUTE")
  end
  
  def self.load(origin, destination, distance)
    unless lookup[origin] == lookup.default
      lookup[origin][destination] = distance
    else
      new_hash = Hash.new("NO SUCH ROUTE")
      new_hash[destination] = distance
      lookup[origin] = new_hash
    end
  end

  def self.distance_between(station, next_station)
    lookup[station][next_station]
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
    lookup[stop].keys
  end

end


class DirectorySearch
  
  def distance_between(*args) #
    Directory.distance_between(*args)
  end

  def total_routes_between(*args)
    routes_between(*args).count
  end

  def distance_along_route(*stations) #
    Directory.distance_along_route(*stations) 
  end

  def routes_between(origin, destination, *opts)
    SearchHelper.route_search(origin, destination, *opts)
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
    SearchHelper.find_all_recombinations(routes, limit)
  end

  def total_routes_by_limit_distance(origin, destination, distance)
    routes_by_limit_distance(origin, destination, distance).count
  end

end

class SearchHelper

  def self.route_search(origin, destination, *opts)
    seed_route = Route.new(origin)
    bounds = set_limits(*opts)
    find_routes(seed_route, destination, *bounds)
  end

  def self.find_routes(route, final_destination, max, min) #depth first search
    trails = [] 
    route.connections.each do |next_stop|
      new_fork = route.new_fork!(next_stop)
      match = evaluate(new_fork, final_destination, max, min)
      trails << match if match
    end
    trails.flatten
  end

  def self.find_all_recombinations(routes, limit)
    unique_routes = Set.new(routes.map{|route| route.stops})
    routes.each do |left_side|
      routes.each do |right_side|
        combo_route = evaluate_combo(left_side, right_side, limit, unique_routes)
        routes << combo_route if combo_route
      end
    end
  end

  private

  def self.evaluate_combo(left_side, right_side, limit, unique_routes)
    total_dist = left_side.distance + right_side.distance
    if total_dist < limit
      new_route = Route.new_splice(left_side, right_side)
      new_route if unique_routes.add?(new_route.stops)
    end
  end

  def self.evaluate(route, final_destination, max, min)
    stops = route.stops.count      
    if route.destination == final_destination && stops >= min
      route
    elsif stops < max
      find_routes(route, final_destination, max, min)
    end
  end

  def self.set_limits(*opts)
    case opts.length
    when 2
      max = opts[0] + 1
      min = opts[1] + 1
    when 1
      max = opts[0] + 1
      min = 0
    when 0
      max = Directory.number_of_stations + 1
      min = 0
    end

    [max, min]
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
    Directory.connections_from(last_stop)
  end

  alias_method :last_stop, :destination

  def new_fork!(next_stop)
    self.class.new_fork(self, next_stop)
  end

  def self.new_fork(route, next_stop)
    new_stops = *route.stops, next_stop
    next_distance = Directory.distance_between(route.last_stop, next_stop)
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
seed_graph = [['A','B',5], ['B','C',4], ['C','D',8], ['D','C',8], ['D','E',6], 
                ['A','D',5], ['C','E',2], ['E','B',3], ['A','E',7]]

Control.new(seed_graph)
c = DirectorySearch.new

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