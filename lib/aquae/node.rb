module Aquae
  class Node
    def initialize name, certificate, hostname, port_number
      @name = name
      @certificate = certificate
      @location = Location.new hostname, port_number
    end

    # The node of this node in the metadata
    attr_reader :name

    # The node's certificate in DER format
    attr_reader :certificate

    # The node's location on the Internet
    attr_reader :location

    Location = Struct.new :hostname, :port_number
  end
end