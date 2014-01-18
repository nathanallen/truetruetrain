class Connections

  LOOKUP = Hash.new("NO SUCH ROUTE")

  def initialize(graph)
    graph.each{|route| new_route(*route)}
  end

  def new_route(origin, destination, distance)
    origin_hash = LOOKUP[origin]
    if origin_hash != LOOKUP.default
      origin_hash[destination] = distance.to_i #
    else
      new_hash = Hash.new("NO SUCH ROUTE")
      new_hash[destination] = distance.to_i #
      LOOKUP[origin] = new_hash
    end
  end

  def distance_between(station, next_station)
    LOOKUP[station][next_station]
  end

  def distance_along_route(*stations)
    distance = 0
    stops = stations.length-1
    stops.times do |i|
      output = distance_between(*stations[i..i+1])
      return output if output == "NO SUCH ROUTE"
      distance += output
    end
    distance
  end

  def total_routes_between(*args)
    routes_between(*args).count
  end

  def routes_between(origin, destination, *opts)
    seed_route = Route.new(origin)
    bounds = set_limits(*opts)
    route_search(seed_route, destination, *bounds)
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

  def set_limits(*opts)
    case opts.length
    when 2
      max = opts[0] + 1
      min = opts[1] + 1
    when 1
      max = opts[0] + 1
      min = 0
    when 0
      max = LOOKUP.keys.length
      min = 0
    end

    [max, min]
  end

  def update(route, stop, dist)
    route_so_far = route.first.dup << stop
    distance_so_far = route.last + dist
    [route_so_far, distance_so_far]
  end

  def find_all_recombinations(routes, limit)
    routes.each do |left_side|
      routes.each do |right_side|
        total_dist = left_side.distance + right_side.distance
        if total_dist < limit
          new_trail = splice_route(left_side.stops, right_side.stops)
          route_already_exists = false
          routes.each{|route| (route_already_exists = true) if route.stops == new_trail }
          routes << Route.new(new_trail,total_dist) unless route_already_exists || new_trail.nil? 
        end
      end
    end
    routes.uniq
  end

  def splice_route(left_trail, right_trail)
    left_trail + right_trail[1..-1]
  end

  def route_search(route, final_destination, max, min) #depth first search
    trails = [] 
    connections = LOOKUP[route.last_stop]
    connections.each_pair do |current_stop, current_distance|
      route_fork = route.new_fork(current_stop, current_distance)
      stops = route_fork.stops.count
      if current_stop == final_destination && stops >= min
        trails << route_fork
      elsif stops < max
        trails += route_search(route_fork, final_destination, max, min)
      end
    end
    trails
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

  alias_method :last_stop, :destination

  def new_fork(new_stop, new_distance)
    fork_stops = [stops, new_stop].flatten
    fork_distance = distance + new_distance
    Route.new(fork_stops, fork_distance)
  end

end



## Driver Code
seed_graph = [['A','B',5], ['B','C',4], ['C','D',8], ['D','C',8], ['D','E',6], 
                ['A','D',5], ['C','E',2], ['E','B',3], ['A','E',7]]

c = Connections.new(seed_graph)

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