
TRAIN_HASH = Hash.new()

def total_distance(*stops)
  output = 0
  stops.each_with_index do |current_stop, i|
    next_stop = stops[i+1]
    if next_stop
      route_value = TRAIN_HASH[current_stop][next_stop]
      return route_value if route_value.is_a? String # ie "NO SUCH ROUTE" error message
      output += route_value
    end
  end
  output
end


def number_of_trips(origin, destination, *opts)
  max = opts[0]
  min = opts[1] || 1
  trail = [origin]
  routes = trail_blaze(trail, destination, max, min)
  routes.count
end

def trail_blaze(trail, destination, max, min) #depth first search
  trails = []
  stops = trail.length
  if stops <= max #### Should this be less than?
    current_stop_hash = TRAIN_HASH[trail[-1]]
    current_stop_hash.keys.each do |stop|
      current_trail = trail.dup << stop
      if stop == destination && stops >= min
        trails << current_trail
      else
        more_trails = trail_blaze(current_trail, destination, max, min)
        trails.concat(more_trails)
      end 
    end
  end
  trails
end

def length_of_shortest_route(origin, destination)
  max = TRAIN_HASH.keys.length
  min = 0
  trail = [[origin], 0]
  routes = shortest_blaze(trail, destination, max, min)
  routes.sort_by!{|route| route.last}
  routes.first.last
end

def shortest_blaze(trail, destination, max, min) #depth first search
  p trail
  trails = []
  stops = trail.length
  if stops < max
    current_stop_hash = TRAIN_HASH[trail.first.last]
    current_stop_hash.each_pair do |stop, dist|
      current_trail = trail.first.dup << stop
      distance = trail.last + dist
      current_thing = [current_trail, distance]
      if stop == destination #&& stops >= min
        trails << current_thing
      elsif current_trail.length <= max ## move this
        more_trails = shortest_blaze(current_thing, destination, max, min)
        trails.concat(more_trails)
      end 
    end
  end
  trails
end

def number_of_unique_routes(origin, destination, distance)
  max = TRAIN_HASH.keys.length
  min = 0
  outer_distance = distance
  trail = [[origin], 0]
  routes = shortest_blaze(trail, destination, max, min)
  # for all combinations of direct routes where x.length + y.length-1 (...) == the_max
  # distance of less than 30...
  p "******"
  p routes
  output = []
  routes.each do |this_route|
    routes.each do |that_route| 
      sum = this_route.last + that_route.last
      if sum < outer_distance
        trail = this_route.first.slice(0..-2) + that_route.first.slice(1..-1)
        routes << [trail, sum]
      end
    end
  end
  p routes.uniq
  routes.uniq.count
end

def update_graph(origin, destination, distance)
  if TRAIN_HASH[origin]
    TRAIN_HASH[origin][destination] = distance.to_i #
  else
    new_hash = Hash.new("NO SUCH ROUTE")
    new_hash[destination] = distance.to_i #
    TRAIN_HASH[origin] = new_hash
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
  # p TRAIN_HASH
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
# p "#1: #{total_distance('A','B','C') == 9}"
# p "#2: #{total_distance('A','D') == 5}"
# p "#3: #{total_distance('A','D','C') == 13}"
# p "#4: #{total_distance('A','E','B','C','D') == 22}"
# p "#5: #{total_distance('A','E','D') == 'NO SUCH ROUTE'}"

# 6. The number of trips starting at C and ending at C with a maximum of 3 stops.  In the sample data below, there are two such trips: C-D-C (2 stops). and C-E-B-C (3 stops).
# 7. The number of trips starting at A and ending at C with exactly 4 stops.  In the sample data below, there are three such trips: A to C (via B,C,D); A to C (via D,C,D); and A to C (via D,E,B).
# p "#6: #{number_of_trips('C','C',3) == 2}"
# p "#7: #{number_of_trips('A','C',4,4) == 3}"

# 8. The length of the shortest route (in terms of distance to travel) from A to C.
# 9. The length of the shortest route (in terms of distance to travel) from B to B.
#p "#8: #{length_of_shortest_route('A','C') == 9}"
#p "#9: #{length_of_shortest_route('B','B') == 9}"

# 10. The number of different routes from C to C with a distance of less than 30.  In the sample data, the trips are: CDC, CEBC, CEBCDC, CDCEBC, CDEBC, CEBCEBC, CEBCEBCEBC.
p "#10: #{number_of_unique_routes('C','C',30) == 7}"
p "CDC, CEBC, CEBCDC, CDCEBC, CDEBC, CEBCEBC, CEBCEBCEBC"