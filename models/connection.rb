class Connection
  attr_reader :origin, :destination, :distance

  def initialize(origin, destination, distance)
    @origin = origin
    @destination = destination
    @distance = distance
  end

end