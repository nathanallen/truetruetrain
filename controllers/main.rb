class Main

  def initialize(graph_strings)
    load_graph(graph_strings)
  end
  
  def build_stations(origin_name, destination_name, distance)
    new_connection = Directory::Connection.new(origin_name, destination_name, distance)
    station = Directory::Station.find(origin_name)
    station ? station.add_connection(new_connection) : Directory::Station.new(origin_name, new_connection)
  end

  private

  def load_graph(graph_strings)
    graph_strings.each do |route_string|
      build_stations(route_string[0], route_string[1], route_string[2].to_i)
    end
  end

end