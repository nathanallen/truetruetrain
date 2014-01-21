class BasicConnection
  attr_reader :origin, :destination, :distance

  def initialize(origin, destination, distance)
    @origin = origin
    @destination = destination
    @distance = distance
  end

end

module Directory
  class Connection < BasicConnection

    @@connections = {}

    def initialize(origin, destination, distance)
      super
      add_connection
    end

    def self.find(origin)
      @@connections[origin]
    end

    def self.all
      @@connections
    end

    private

    def add_connection
      @@connections[self.origin] = self
    end

  end
end