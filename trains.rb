
TRAIN_ROUTES = Hash.new("NO SUCH ROUTE")

def distance_along_route(*stops)
  distance = 0
  legs = stops.length-1
  legs.times do |i|
    stations = stops[i..i+1]
    output = distance_between(*stations)
    return output if output == "NO SUCH ROUTE"
    distance += output
  end
  distance
end

def distance_between(current_station, next_station)
  TRAIN_ROUTES[current_station][next_station]
end


def number_of_trips(origin, destination, *opts)
  max = opts[0] + 1 # total_stops
  min = (opts[1] || 0) + 1 #total_stops
  trail = [[origin],0]
  routes = find_routes(trail, destination, max, min)
  routes.count
end

def find_routes(route, destination, max, min) #depth first search
  trails = []
  connections = TRAIN_ROUTES[route.first.last]
  connections.each_pair do |stop, dist|
    trail_so_far = route.first.dup << stop
    distance_so_far = route.last + dist
    current_route = [trail_so_far, distance_so_far]
    if stop == destination && trail_so_far.length >= min
      trails << current_route
    elsif trail_so_far.length < max
      more_trails = find_routes(current_route, destination, max, min)
      trails += more_trails
    end 
  end
  trails
end

def default_find_routes(origin, destination)
  max = TRAIN_ROUTES.keys.length
  min = 0
  trail = [[origin], 0]
  routes = find_routes(trail, destination, max, min)
end

def length_of_shortest_route(origin, destination)
  routes = default_find_routes(origin, destination)
  routes.sort_by!{|route| route.last}
  routes.first.last
end


def unique_routes(origin, destination, distance)
  routes = default_find_routes(origin, destination)

  outer_bound = distance
  routes.each do |this_route|
    routes.each do |that_route|
      new_route = splice_route(this_route, that_route, outer_bound)
      routes << new_route unless new_route.nil?
    end
  end
  routes.uniq
end

def number_of_unique_routes(origin, destination, distance)
  unique_routes(origin, destination, distance).count
end

def splice_route(this_route, that_route, outer_bound)
  sum = this_route.last + that_route.last
  if sum < outer_bound
    trail = this_route.first[0..-2] + that_route.first[1..-1]
    [trail, sum]
  end
end

# def routes_by_stop_count()
# end

# def routes_by_distance_along_route()
# end

# def shortest_route()
# end

# def total_routes()
# end


def update_graph(origin, destination, distance)
  if TRAIN_ROUTES[origin] != TRAIN_ROUTES.default
    TRAIN_ROUTES[origin][destination] = distance.to_i #
  else
    new_hash = Hash.new("NO SUCH ROUTE")
    new_hash[destination] = distance.to_i #
    TRAIN_ROUTES[origin] = new_hash
  end
end

def load_graph(graph_strings)
  graph_strings.each do |route_string|
    # origin = route_string[0]
    # destination = route_string[1]
    # distance = route_string[2]
    update_graph(*route_string.split(''))
  end
  # p "LOADING GRAPH..."
  # p TRAIN_ROUTES
  # p "+++++++++++++"
end

## Driver Code
graph_strings = ['AB5', 'BC4', 'CD8', 'DC8', 'DE6', 'AD5', 'CE2', 'EB3', 'AE7']#, 'CZ9', 'ZC9', 'ZD9']
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

# # 6. The number of trips starting at C and ending at C with a maximum of 3 stops.  In the sample data below, there are two such trips: C-D-C (2 stops). and C-E-B-C (3 stops).
# # 7. The number of trips starting at A and ending at C with exactly 4 stops.  In the sample data below, there are three such trips: A to C (via B,C,D); A to C (via D,C,D); and A to C (via D,E,B).
# p "#6: #{number_of_trips('C','C',3) == 2}"
# p "#7: #{number_of_trips('A','C',4,4) == 3}"
# #p "ABCDC, ADCDC, ADEBC"

# # 8. The length of the shortest route (in terms of distance to travel) from A to C.
# # 9. The length of the shortest route (in terms of distance to travel) from B to B.
# p "#8: #{length_of_shortest_route('A','C') == 9}"
# p "#9: #{length_of_shortest_route('B','B') == 9}"

# # 10. The number of different routes from C to C with a distance of less than 30.  In the sample data, the trips are: CDC, CEBC, CEBCDC, CDCEBC, CDEBC, CEBCEBC, CEBCEBCEBC.
# p "#10: #{number_of_unique_routes('C','C',30) == 7}"
# #p "CDC, CEBC, CEBCDC, CDCEBC, CDEBC, CEBCEBC, CEBCEBCEBC"