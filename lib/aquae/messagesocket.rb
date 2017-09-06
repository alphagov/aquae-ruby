require_relative 'protos/transport.pb.rb'
require_relative 'protos/messaging.pb.rb'

module Aquae
  class MessageSocket
    # Wraps an EncapsulationSocket and performs de/serialisation of messages

    def initialize node, encapsulation_socket
      # @param encapsulation_socket [EncapsulationSocket]
      #   An open socket which returns one message per call to read
      @node = node
      @socket = encapsulation_socket
    end

    # The node this socket is connected to
    attr_reader :node

    def write message
      unless TYPES.value? message.class
        raise TypeError.new "Unrecognised message of type #{message.class} passed"
      end

      type = TYPES.invert[message.class]
      @socket.write type, message.encode
    end

    def read
      type, payload = @socket.read
      ruby_type = TYPES[type]
      ruby_type.decode payload
    rescue Protobuf::Error
      # TODO: log error? or send it upwards?
    end

    def close
      @socket.close
    end

    # Pre-compute the mapping of enum to supported message types
    TYPES = Aquae::Transport::Header::Type.enums.map do |enum|
      typename = enum.name.to_s.downcase.split('_').map(&:capitalize).join
      type = Aquae::Messaging.const_get typename
      [enum, type]
    end.to_h
  end
end
