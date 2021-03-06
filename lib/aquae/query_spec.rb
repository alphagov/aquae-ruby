require 'forwardable'

module Aquae
  class QuerySpec
    extend Forwardable

    def initialize name
      @name = name
    end

    # The name of the query
    attr_reader :name

    # The nodes that can implement the query
    def nodes
      choices.map(&:node).uniq_by(&:name)
    end

    # The choices for the query
    attr_accessor :choices

    # True if the named node implements the query
    def implemented_by? name
      nodes.map(&:name).include? name
    end

    delegate :== => :name
    alias_method :eql?, :==
    alias_method :to_s, :name

    # Describes the details of who and how a query is implemented
    class Implementation
      def initialize node, query_for, required_queries, required_matches=nil
        @node = node
        @query_for = query_for
        @required_queries = required_queries
        @required_matches = required_matches
      end

      # True if this implentation will require a match
      def requires_matching?
        !required_matches.nil?
      end

      attr_reader :node
      attr_reader :query_for
      attr_reader :required_queries
      attr_reader :required_matches
    end
  end
end