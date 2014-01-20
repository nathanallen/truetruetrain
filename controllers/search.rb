class SearchController < Main
  require 'set'

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
    stops = route.total_stops    
    if route.destination == final_destination && stops >= min
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