class Route < Directory::Connection
  attr_reader :connections

  def initialize(connections)
    @connections = *connections
  end

  def origin
    @origin ||= connections.first.origin
  end

  def destination
    @destination ||= connections.last.destination
  end

  alias_method :terminus, :destination

  def distance
    @distance ||= calculate_distance
  end  

  def total_stops
    connections.count
  end

  def station_names
    [connections.first.origin, *connections.map{|c| c.destination}]
  end

  def new_fork!(next_connections)
    self.class.new_fork(self, next_connections)
  end

  def self.new_fork(route, next_connections)
    new_connections = *route.connections, *next_connections
    self.new(new_connections)
  end

  private

  def calculate_distance
    connections.inject(0){|memo,c| memo += c.distance}
  end

end