class StationDirectory

  @@stations = {}

  def initialize(name, *connections)
    add_station
  end

  def self.find(station_name)
    @@stations[station_name]
  end

  def self.connections_from(station_name)
    station = @@stations[station_name]
    station ? station.connections : "NO SUCH ROUTE"
  end

  def self.all
    @@stations
  end

  private

  def add_station
    @@stations[self.station_name] = self
  end
end

class Station < StationDirectory
  attr_reader :connections_hash, :station_name
  
  def initialize(name, *connections)
    @station_name = name
    @connections_hash = {}
    add_connections(connections)
    super
  end

  def distance_to_connecting_station(station_name)
    connection = connections_hash[station_name]
    connection ? connection.distance : "NO SUCH ROUTE"
  end

  def connection_names
    connections_hash.keys
  end

  def connections
    connections_hash.values
  end

  def add_connection(new_connection)
    connections_hash[new_connection.destination] = new_connection
  end

  private

  def add_connections(new_connections)
    new_connections.each{|c| add_connection(c)}
  end

end
