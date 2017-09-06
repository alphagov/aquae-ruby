require 'openssl'
require_relative 'messagesocket'
require_relative 'encapsulationsocket'

module Aquae
  class Endpoint
    # Runs a TCP server to accept new connections
    # and opens TCP client connections when required.

    def initialize metadata, key, node
      metadata = metadata
      tcp_server = TCPServer.new node.location.hostname, node.location.port_number
      @certs = Endpoint::make_certs(metadata)
      @context = Endpoint::make_context node, key, @certs.keys
      @ssl_server = OpenSSL::SSL::SSLServer.new tcp_server, @context
    end

    def self.make_certs metadata
      metadata.nodes.map {|node| [node.certificate, node]}.to_h
    end

    def self.make_context node, key, certs
      context = OpenSSL::SSL::SSLContext.new
      context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      context.cert_store = Endpoint::make_store certs
      context.cert = OpenSSL::X509::Certificate.new node.certificate
      context.key = OpenSSL::PKey::RSA.new key
      context
    end

    def self.make_store ders
      certs = ders.map &OpenSSL::X509::Certificate.method(:new)
      store = OpenSSL::X509::Store.new
      certs.each &store.method(:add_cert)
      store.freeze
      store
    end

    def make_socket ssl_socket
      node = @certs[ssl_socket.peer_cert.to_der]
      Aquae::MessageSocket.new node, Aquae::EncapsulationSocket.new(ssl_socket)
    end

    def accept_messages
      raise ArgumentError.new("no block given") unless block_given?
      loop do
        socket = make_socket @ssl_server.accept
        yield socket
      end
    end

    def connect_to node
      tcp_socket = TCPSocket.new node.location.hostname, node.location.port_number
      ssl_socket = OpenSSL::SSL::SSLSocket.new tcp_socket, @context
      ssl_socket.sync_close = true
      make_socket ssl_socket.connect
    end

    def nodes=
      # Updates the metadata used by this endpoint.
      # TODO: Any nodes no longer in the metadata will have
      # their connections closed?
    end
  end
end
