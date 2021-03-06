class TreeTest < Test::Unit::TestCase
  
  def setup
    @tree    = Stylish::Stylesheet.new
    @node    = Stylish::Tree::SelectorScope.new(Stylish::Selector.new(".test"))
    @rule    = Stylish::Rule.new([Stylish::Selector.new("p")],
                 [Stylish::Declaration.new("font-weight", "bold")])
    @comment = Stylish::Comment.new("Comment header",
                 {:author => "Some Body"})
  end
  
  def test_appending
    @node << @rule
    @tree << @node
    assert_equal(@tree[0], @node)
    assert_equal(@node[0], @rule)
  end
  
  def test_setting
    @tree[1] = @node
    assert_equal(@tree[1], @node)
    
    @tree[1] = @rule
    assert_equal(@tree[1], @rule)
  end
  
  def test_rules_collation
    @node << @rule
    @node << @rule
    @node << @comment
    @tree << @node
    @tree << @node
    
    assert_equal(6, @tree.leaves.length)
    assert_equal(4, @tree.rules.length)
    assert_equal(2, @tree.comments.length)
  end
  
  def test_node_reader
    @tree << @node
    @tree << @rule
    
    assert_equal(2, @tree.nodes.length)
    assert_equal(2, @tree.to_a.length)
  end
  
  def test_selector_serialisation
    selector = Stylish::Selector.new(".parent > .child")
    onde = Stylish::Tree::SelectorScope.new(selector)
    @node << @rule
    onde  << @rule
    @tree << @node
    @tree << onde
    
    assert_equal(".test p {font-weight:bold;}" + "\n" +
      ".parent > .child p {font-weight:bold;}", @tree.to_s)
  end
end
