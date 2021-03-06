require 'test-unit'
require_relative '../lib/aquae/query_graph'
require_relative '../lib/aquae/query_spec'

class QueryGraphTest < Test::Unit::TestCase
  def question_fixture name
    Aquae::QuerySpec.new name
  end

  def choice_for parent, *children
    Aquae::QuerySpec::Implementation.new nil, parent, children
  end

  def graph_of number
    fixtures = number.times.map(&:to_s).map(&method(:question_fixture))
    graph = Aquae::QueryGraph.new
    fixtures.each &graph.method(:add_query)
    graph
  end

  test 'single_query? for empty graph' do
    assert_false graph_of(0).single_query?
  end

  test 'single_query? for graph of two independent queries' do
    graph = graph_of(2)
    q1, q2 = graph.leaf_queries.first
    graph.add_choice choice_for q1
    graph.add_choice choice_for q2
    assert_false graph.single_query?
  end

  test 'single_query? for graph of one query' do
    graph = graph_of(1)
    query = graph.leaf_queries.first
    graph.add_choice choice_for query
    assert_true graph.single_query?
  end

  test 'single_query? for graph with two parent queries' do
    graph = graph_of(3)
    child, *parents = graph.leaf_queries
    graph.add_choice choice_for parents.first, child
    graph.add_choice choice_for parents.last, child
    graph.add_choice choice_for child
    assert_false graph.single_query?
  end

  test 'single_query? for graph with one parent and two children' do
    graph = graph_of(3)
    parent, *children = graph.leaf_queries
    graph.add_choice choice_for parent, children.first
    graph.add_choice choice_for parent, children.last
    graph.add_choice choice_for children.first
    graph.add_choice choice_for children.last
    assert_true graph.single_query?
  end

  test 'single_query? for three generational graph' do
    graph = graph_of(3)
    grandparent, parent, child = graph.leaf_queries
    graph.add_choice choice_for grandparent, parent
    graph.add_choice choice_for parent, child
    graph.add_choice choice_for child
    assert_true graph.single_query?
  end

  test 'choices_resolved? for empty graph' do
    assert_true graph_of(0).choices_resolved?
  end

  test 'choices_resolved? for graph of one query' do
    graph = graph_of(1)
    query = graph.leaf_queries.first
    graph.add_choice choice_for query
    assert_true graph.choices_resolved?
  end

  test 'choices_resolved? for graph with two parent queries' do
    graph = graph_of(3)
    child, *parents = graph.leaf_queries
    graph.add_choice choice_for parents.first, child
    graph.add_choice choice_for parents.last, child
    graph.add_choice choice_for child
    assert_true graph.choices_resolved?
  end

  test 'choices_resolved? for graph with one parent and two choices' do
    graph = graph_of(3)
    parent, *children = graph.leaf_queries
    graph.add_choice choice_for parent, children.first
    graph.add_choice choice_for parent, children.last
    graph.add_choice choice_for children.first
    graph.add_choice choice_for children.last
    assert_false graph.choices_resolved?
  end

  test 'choices_resolved? for graph with one parent and two requirements' do
    graph = graph_of(3)
    parent, *children = graph.leaf_queries
    graph.add_choice choice_for parent, *children
    graph.add_choice choice_for children.first
    graph.add_choice choice_for children.last
    assert_true graph.choices_resolved?
  end

  test 'graph with one parent and one choice to_plans creates one plan' do
    graph = graph_of(2)
    parent, child = graph.leaf_queries
    graph.add_choice choice_for parent, child
    graph.add_choice choice_for child
    plans = graph.to_plans(parent)
    assert_equal 1, plans.size
    assert_same parent, plans.first.root_query
    assert_equal 1, plans.first.leaf_queries.size
    assert_same child, plans.first.leaf_queries.first
  end

  test 'graph with one parent and two choices to_plans creates two plans' do
    graph = graph_of(3)
    parent, *children = graph.leaf_queries
    graph.add_choice choice_for parent, children.first
    graph.add_choice choice_for parent, children.last
    graph.add_choice choice_for children.first
    graph.add_choice choice_for children.last
    plans = graph.to_plans(parent)
    assert_equal 2, plans.size
    plans.each do |plan|
      assert_same parent, plan.root_query
      assert_equal 1, plan.leaf_queries.size
    end
    assert_equal children, plans.flat_map(&:leaf_queries)
  end

  test 'graph with one parent and two requirements to_plans creates two plans' do
    graph = graph_of(3)
    parent, *children = graph.leaf_queries
    graph.add_choice choice_for parent, *children
    graph.add_choice choice_for children.first
    graph.add_choice choice_for children.last
    plans = graph.to_plans(parent)
    assert_equal 1, plans.size
    assert_same parent, plans.first.root_query
    assert_equal 2, plans.first.leaf_queries.size
    assert_equal children, plans.flat_map(&:leaf_queries)
  end

  test 'three generational graph to_plans contains all choices' do
    graph = graph_of(3)
    grandparent, parent, child = graph.leaf_queries
    graph.add_choice (grandparent_choice = choice_for(grandparent, parent))
    graph.add_choice (parent_choice = choice_for(parent, child))
    graph.add_choice (child_choice = choice_for(child))
    plans = graph.to_plans(grandparent)
    assert_equal 1, plans.size
    assert_equal 3, plans.first.all_choices.size
    assert_include plans.first.all_choices, grandparent_choice
    assert_include plans.first.all_choices, parent_choice
    assert_include plans.first.all_choices, child_choice
  end
end
