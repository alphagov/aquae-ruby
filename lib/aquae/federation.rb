require_relative 'query_spec'
require_relative 'node'

module Aquae
  class Federation
    def initialize proto
      @proto = proto
      make_nodes
      make_queries
    end

    def query name
      @queries[name]
    end

    def queries
      @queries.values
    end

    def node name
      @nodes[name]
    end

    def nodes
      @nodes.values
    end

    private
    def make_queries
      # Generate all the query objects
      @queries = @proto.query.map do |query_proto|
        [query_proto.name, Aquae::QuerySpec.new(query_proto.name)]
      end.to_h

      # Now fill in the choices
      @proto.query.each do |query_proto|
        query = @queries[query_proto.name]
        query.choices = Federation::impls_for(query_proto).map do |node, required_queries|
          Aquae::QuerySpec::Implementation.new @nodes[node.name], query, required_queries.map {|r| @queries[r] }, node.matching_requirements
        end
      end
    end

    def make_nodes
      @nodes = @proto.node.map do |node_proto|
        [node_proto.name, Aquae::Node.new(node_proto.name, node_proto.certificate, node_proto.location.hostname, node_proto.location.port_number)]
      end.to_h
    end

    def self.impls_for query_proto
      requires = query_proto.choice.empty? ? [[]] : query_proto.choice.map(&:required_query)
      query_proto.node.product requires
    end
  end
end