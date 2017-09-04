require_relative 'query_spec'

module Aquae
  class Federation
    def initialize proto
      @proto = proto
      make_queries
    end

    def query name
      @queries[name]
    end

    def queries
      @queries.values
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
          Aquae::QuerySpec::Implementation.new node, query, required_queries.map {|r| @queries[r] }
        end
      end
    end

    def self.impls_for query_proto
      requires = query_proto.choice.empty? ? [[]] : query_proto.choice.map(&:requiredQuery)
      query_proto.node.product requires
    end
  end
end