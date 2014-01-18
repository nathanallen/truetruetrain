
TRAIN_CONNECTIONS = Hash.new("NO SUCH ROUTE")
ROUTE_DISTANCES_CACHE = {}
SPLICE_CACHE = {}

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

def distance_between(station, next_station)
  TRAIN_CONNECTIONS[station][next_station]
end

def from(origin)
  [[origin],0]
end

def bounds(*max_min)
  case max_min.length
  when 2
    max = max_min[0] + 1
    min = max_min[1] + 1
  when 1
    max = max_min[0] + 1
    min = 0
  when 0
    max = TRAIN_CONNECTIONS.keys.length
    min = 0
  end

  [max, min]
end

def number_of_trips(*args)
  trips(*args).count
end

def trips(origin, destination, *max_min)
  find_routes(from(origin), destination, *bounds(*max_min))
end

def update_route(route, stop, dist)
  route_so_far = route.first.dup << stop
  distance_so_far = route.last + dist
  [route_so_far, distance_so_far]
end

def find_routes(route_data, destination, max, min) #depth first search
  trails = []
  last_stop = route_data.first.last
  connections = TRAIN_CONNECTIONS[last_stop]
  connections.each_pair do |current_stop, current_distance|
    route_so_far = update_route(route_data, current_stop, current_distance)
    stops = route_so_far.first.count
    if current_stop == destination && stops >= min
      trails << route_so_far
    elsif stops < max
      trails += find_routes(route_so_far, destination, max, min)
    end 
  end
  trails
end

def length_of_shortest_route(origin, destination)
  routes = trips(origin, destination)
  routes.sort_by!{|route| route.last}
  routes.first.last
end


def routes_limit_distance(origin, destination, distance)
  routes = trips(origin, destination)
  find_all_route_combinations(routes, distance)
end

def number_of_unique_routes(origin, destination, distance)
  routes_limit_distance(origin, destination, distance).count
end

def find_all_route_combinations(routes, outer_bound)
  routes.each do |this_route|
    routes.each do |that_route|
      route = quick_splice(this_route, that_route, outer_bound)
      routes << route unless route.nil?
    end
  end
  routes.uniq
end

def quick_splice(this_route, that_route, outer_bound)
  r1, r2 = this_route.first, that_route.first
  cache = SPLICE_CACHE[r1]
  return cache[r2] if cache && cache[r2]

  output = splice_route(this_route, that_route, outer_bound)
  cache_splice(output, cache, r2)
  output || nil
end

def cache_splice(output, cache, r2)
  cache ? cache[r2] = output : cache = {[r2] => output}
end

def splice_route(this_route, that_route, outer_bound)
  r1, r2 = this_route.first, that_route.first
  sum = this_route.last + that_route.last
  if sum < outer_bound
    new_trail = r1[0..-2] + r2[1..-1]
    output = [new_trail, sum]
  end
end

def update_graph(origin, destination, distance)
  origin_hash = TRAIN_CONNECTIONS[origin]
  if origin_hash != TRAIN_CONNECTIONS.default
    origin_hash[destination] = distance.to_i #
  else
    new_hash = Hash.new("NO SUCH ROUTE")
    new_hash[destination] = distance.to_i #
    origin_hash = new_hash
  end
end

def load_graph(graph_strings)
  graph_strings.each do |route_string|
    # origin = route_string[0]
    # destination = route_string[1]
    # distance = route_string[2]
    update_graph(*route_string.split(''))
  end
end

## Driver Code
graph_strings = ['AB5', 'BC4', 'CD8', 'DC8', 'DE6', 'AD5', 'CE2', 'EB3', 'AE7']
load_graph(graph_strings)

# 1. The distance of the route A-B-C.
# 2. The distance of the route A-D.
# 3. The distance of the route A-D-C.
# 4. The distance of the route A-E-B-C-D.
# 5. The distance of the route A-E-D.
p "#1: #{distance_along_route('A','B','C') == 9}"
p "#2: #{distance_along_route('A','D') == 5}"
p "#3: #{distance_along_route('A','D','C') == 13}"
p "#4: #{distance_along_route('A','E','B','C','D') == 22}"
p "#5: #{distance_along_route('A','E','D') == 'NO SUCH ROUTE'}"

# 6. The number of trips starting at C and ending at C with a maximum of 3 stops.  In the sample data below, there are two such trips: C-D-C (2 stops). and C-E-B-C (3 stops).
# 7. The number of trips starting at A and ending at C with exactly 4 stops.  In the sample data below, there are three such trips: A to C (via B,C,D); A to C (via D,C,D); and A to C (via D,E,B).
p "#6: #{number_of_trips('C','C',3) == 2}"
p "#7: #{number_of_trips('A','C',4,4) == 3}"
#p "ABCDC, ADCDC, ADEBC"

# 8. The length of the shortest route (in terms of distance to travel) from A to C.
# 9. The length of the shortest route (in terms of distance to travel) from B to B.
p "#8: #{length_of_shortest_route('A','C') == 9}"
p "#9: #{length_of_shortest_route('B','B') == 9}"

# 10. The number of different routes from C to C with a distance of less than 30.  In the sample data, the trips are: CDC, CEBC, CEBCDC, CDCEBC, CDEBC, CEBCEBC, CEBCEBCEBC.
p "#10: #{number_of_unique_routes('C','C',30) == 7}"
#p "CDC, CEBC, CEBCDC, CDCEBC, CDEBC, CEBCEBC, CEBCEBCEBC"