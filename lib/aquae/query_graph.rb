require 'rgl/adjacency'
require 'rgl/traversal'
require 'rgl/implicit'
require 'rgl/topsort'

module Aquae
  # Represents a graph of queries. There may be multiple high-level queries
  # or only one. Each query may have only one choice, or there may be multiple.
  class QueryGraph
    attr_reader :graph
    attr_reader :choices

    def initialize *others
      @graph = RGL::DirectedAdjacencyGraph.new Set, *others.map(&:graph)
      @choices = Hash.new {|h, q| h[q] = Set.new }
      others.map(&:choices).each do |other|
        other.keys.each {|k| @choices[k].merge other[k] }
      end
    end

    def add_query query
      @graph.add_vertex query
      query
    end

    def add_choice choice
      choice.required_queries.each do |required|
        @graph.add_edge choice.query_for, required
        unless @graph.acyclic?
          @graph.remove_edge choice.query_for, required
          raise ArgumentError, "Choice would create a cycle in query graph"
        end
      end
      @choices[choice.query_for].add choice
      choice
    end

    def query_tree query
      graph = @graph.bfs_search_tree_from query
      # Make sure query is added, might not be present if
      # query has no children
      graph.add_vertex query
      graph
    end

    def leaf_queries
      @graph.vertices_filtered_by {|v| @graph.out_degree(v) == 0 }.to_a
    end

    def root_query
      @graph.empty? ? nil : @graph.topsort_iterator.first
    end

    # True if this is a query tree for a single query
    def single_query?
      @graph.empty? ? false : query_tree(root_query).size == @graph.size
    end

    # True if all the choices in this tree have been resolved
    # (i.e. that each query only has one choice)
    def choices_resolved?
      @choices.values.map(&:size).all? {|size| size == 1 }
    end

    # Splits a single query with multiple choices at different levels out
    # into multiple trees, one for each combination of queries.
    def to_plans query
      if @graph.out_degree(query) == 0
        # Leaf node, generate a graph of just this query
        g = self.class.new
        g.add_query query
        [g]
      else
        @choices[query].map do |choice|
          # Get the choice trees for each req. query,
          trees = choice.required_queries.map &method(:to_plans)
          # generate every possible combination of choices,
          combinations = trees.first.product *trees.drop(1)
          # and combine them all into a single graph for this choice
          combinations.map {|graphs| self.class.new *graphs }.each do |graph|
            graph.add_query query
            graph.add_choice choice
          end
        end.flatten
      end
    end

    # Create a new graph from a set of queries
    def self.populate *queries
      graph = new
      queries.each do |query|
        graph.add_query query
        query.choices.each do |choice|
          graph.add_choice choice
        end
      end
      graph
    end
  end
end
