require 'test-unit'
require_relative '../lib/aquae/protos/metadata.pb'
require_relative 'query_graph_fixture'

class QueryGraphMatchingSpecTest < Test::Unit::TestCase
  include QueryGraphFixtures

  # Load id field constants
  Aquae::Metadata::MatchingSpec::IdFields.constants.each do |const|
    self.const_set(const, Aquae::Metadata::MatchingSpec::IdFields.const_get(const))
  end

  def node
    node_fixture 'node'
  end

  def matching_set_with_surname
    match_fixture required: [SURNAME]
  end

  def matching_set_with_surname_disambiguator
    match_fixture disambiguator: [SURNAME]
  end

  def matching_set_with_postcode
    match_fixture required: [POSTCODE]
  end

  def matching_set_with_postcode_disambiguator
    match_fixture disambiguator: [POSTCODE]
  end

  def matching_set_with_ni_confidence_attribute
    match_fixture confidence: ['NI#']
  end

  def question_with_matching
    graph_of(1) do |graph|
      parent = graph.leaf_queries.first
      graph.add_choice choice_for node, parent, [], matching_set_with_surname
    end
  end

  def child_question_with_matching
    graph_of(2) do |graph|
      parent, child = graph.leaf_queries
      graph.add_choice choice_for node, parent, [child]
      graph.add_choice choice_for node, child, [], matching_set_with_surname
    end
  end

  def two_required_child_questions_with_matching
    graph_of(3) do |graph|
      parent, child1, child2 = graph.leaf_queries
      graph.add_choice choice_for node, parent, [child1, child2]
      graph.add_choice choice_for node, child1, [], matching_set_with_surname
      graph.add_choice choice_for node, child2, [], matching_set_with_postcode
    end
  end

  def two_required_child_questions_with_disambiguators
    graph_of(3) do |graph|
      parent, child1, child2 = graph.leaf_queries
      graph.add_choice choice_for node, parent, [child1, child2]
      graph.add_choice choice_for node, child1, [], matching_set_with_surname_disambiguator
      graph.add_choice choice_for node, child2, [], matching_set_with_postcode_disambiguator
    end
  end

  def two_required_child_questions_with_same_disambiguator
    graph_of(3) do |graph|
      parent, child1, child2 = graph.leaf_queries
      graph.add_choice choice_for node, parent, [child1, child2]
      graph.add_choice choice_for node, child1, [], matching_set_with_postcode_disambiguator
      graph.add_choice choice_for node, child2, [], matching_set_with_postcode_disambiguator
    end
  end

  def two_required_child_questions_with_same_confidence_attribute
    graph_of(3) do |graph|
      parent, child1, child2 = graph.leaf_queries
      graph.add_choice choice_for node, parent, [child1, child2]
      graph.add_choice choice_for node, child1, [], matching_set_with_ni_confidence_attribute
      graph.add_choice choice_for node, child2, [], matching_set_with_ni_confidence_attribute
    end
  end

  def assert_matching_spec graph, args
    spec = graph.matching_requirements(graph.root_query)
    assert_equal args[:required] || [], spec.required
    assert_equal args[:disambiguator] || [], spec.disambiguator
    assert_equal args[:confidence] || [], spec.confidence
  end

  test 'returns spec from a single query' do
    assert_matching_spec question_with_matching, required: [SURNAME]
  end

  test 'returns spec from a child query' do
    assert_matching_spec child_question_with_matching, required: [SURNAME]
  end

  test 'combines specs from multiple child queries' do
    assert_matching_spec two_required_child_questions_with_matching, required: [SURNAME, POSTCODE]
  end

  test 'combines disambiguating specs from multiple child queries' do
    assert_matching_spec two_required_child_questions_with_disambiguators, disambiguator: [SURNAME, POSTCODE]
  end

  test 'multiple common disambiguators are promoted to required' do
    assert_matching_spec two_required_child_questions_with_same_disambiguator, required: [POSTCODE]
  end

  test 'multiple common confidence attributes remain as confidence attributes' do
    assert_matching_spec two_required_child_questions_with_same_confidence_attribute, confidence: ['NI#']
  end
end
