require_relative '../lib/aquae/query_graph'
require_relative '../lib/aquae/query_spec'
require_relative '../lib/aquae/node'
require_relative '../lib/aquae/protos/metadata.pb'

module QueryGraphFixtures
  def question_fixture name
    Aquae::QuerySpec.new name
  end

  def node_fixture name
    Aquae::Node.new name, nil, nil, nil
  end

  def match_fixture args={}
    Aquae::Metadata::MatchingSpec.new args
  end

  def choice_for node, parent, children=[], match=nil
    Aquae::QuerySpec::Implementation.new node, parent, children, match
  end

  def graph_of number
    fixtures = number.times.map(&:to_s).map(&method(:question_fixture))
    graph = Aquae::QueryGraph.new
    fixtures.each &graph.method(:add_query)
    yield graph if block_given?
    graph
  end
end