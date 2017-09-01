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
    end

    def add_choice source, choice
      choice.requiredQuery.each do |query|
        @graph.add_edge source, query
        unless @graph.acyclic?
          @graph.remove_edge source, query
          raise ArgumentError, "Choice would create a cycle in query graph"
        end
      end
      @choices[source].add choice
    end

    def choices_for query
      @choices[query]
    end

    def query_tree query
      @graph.bfs_search_tree_from query
    end

    def leaf_queries
      @graph.vertices_filtered_by {|v| @graph.out_degree(v) == 0 }.to_a
    end

    # True if this is a query tree for a single query
    def single_query?
      reverse = @graph.reverse
      reverse.vertices_filtered_by {|v| reverse.out_degree(v) == 0 }.one?
    end

    # True if all the choices in this tree have been resolved
    # (i.e. that each query only has one choice)
    def choices_resolved?
      @choices.values.map(&:size).all? {|size| size == 1 }
    end

    # Splits a single query with multiple choices at different levels out
    # into multiple trees, one for each combination of queries.
    def trees_for query
      if @graph.out_degree(query) == 0
        # Leaf node, generate a graph of just this query
        g = self.class.new
        g.add_query query
        [g]
      else
        @choices[query].map do |choice|
          # Get the choice trees for each req. query,
          trees = choice.requiredQuery.map &method(:trees_for)
          # generate every possible combination of choices,
          combinations = trees.first.product *trees.drop(1)
          # and combine them all into a single graph for this choice
          combinations
            .map {|graphs| self.class.new *graphs }
            .each {|graph| graph.add_choice query, choice }
        end.flatten
      end
    end
  end
end

if __FILE__ == $0
  require 'rgl/dot'
  require 'aquae/protos/metadata.pb'
  g = Viaduct::QueryGraph.new
  g.add_query '1'
  g.add_query '2'
  g.add_query '3'
  g.add_query '4'
  g.add_query '5'
  g.add_query '6'
  g.add_query '7'
  g.add_query '0'
  g.add_choice '1', Aquae::Metadata::Choice.new(requiredQuery: ['2', '3'])
  g.add_choice '1', Aquae::Metadata::Choice.new(requiredQuery: ['4'])
  g.add_choice '3', Aquae::Metadata::Choice.new(requiredQuery: ['5'])
  g.add_choice '4', Aquae::Metadata::Choice.new(requiredQuery: ['5'])
  g.add_choice '5', Aquae::Metadata::Choice.new(requiredQuery: ['6'])
  g.add_choice '5', Aquae::Metadata::Choice.new(requiredQuery: ['7'])
  g.add_choice '6', Aquae::Metadata::Choice.new(requiredQuery: ['1'])

  puts "Edges:"
  p g.graph.edges
  p g.trees_for '1'
  File.open('graph.dot', 'w') do |f|
    g.trees_for('1').each do |graph|
      graph.graph.print_dotted_on({}, f)
    end
  end
end