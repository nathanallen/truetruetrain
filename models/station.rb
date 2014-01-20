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
     @@stations[station_name] ? @@stations[station_name].connections : "NO SUCH ROUTE"
  end

  def self.all
    @@stations
  end

  def add_connection(new_connection)
    connections_hash[new_connection.destination] = new_connection
  end

  def distance_to(station_name)
    connections_hash[station_name] ? connections_hash[station_name].distance : "NO SUCH ROUTE"
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