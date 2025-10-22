require_relative './environment.rb'

describe 'Atom' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    DB[:atoms].delete
    DB[:atom_links].delete
    DB[:atomspace_shares].delete
    @site = Fabricate(:site)
  end

  it 'creates a concept node' do
    atom = Atom.create_node(
      site_id: @site.id,
      type_name: 'ConceptNode',
      name: 'Alice'
    )
    
    assert atom.persisted?
    assert_equal 'node', atom.atom_type
    assert_equal 'ConceptNode', atom.type_name
    assert_equal 'Alice', atom.name
    assert atom.node?
    refute atom.link?
  end

  it 'creates a predicate node with value' do
    atom = Atom.create_node(
      site_id: @site.id,
      type_name: 'PredicateNode',
      name: 'likes',
      value: { description: 'affection relationship' }
    )
    
    assert atom.persisted?
    assert_equal({ 'description' => 'affection relationship' }, atom.parsed_value)
  end

  it 'creates a link atom' do
    node1 = Atom.create_node(site_id: @site.id, type_name: 'ConceptNode', name: 'Alice')
    node2 = Atom.create_node(site_id: @site.id, type_name: 'ConceptNode', name: 'Bob')
    
    link = Atom.create_link(
      site_id: @site.id,
      type_name: 'SimilarityLink',
      outgoing: [node1.id, node2.id]
    )
    
    assert link.persisted?
    assert_equal 'link', link.atom_type
    assert_equal 'SimilarityLink', link.type_name
    assert link.link?
    refute link.node?
    
    outgoing = link.outgoing
    assert_equal 2, outgoing.length
    assert_equal node1.id, outgoing[0].id
    assert_equal node2.id, outgoing[1].id
  end

  it 'sets and gets truth values' do
    atom = Atom.create_node(
      site_id: @site.id,
      type_name: 'ConceptNode',
      name: 'test',
      tv: { strength: 0.8, confidence: 0.9 }
    )
    
    assert_equal 0.8, atom.truth_value_strength
    assert_equal 0.9, atom.truth_value_confidence
    
    tv = atom.tv
    assert_equal 0.8, tv[:strength]
    assert_equal 0.9, tv[:confidence]
  end

  it 'sets and gets attention values' do
    atom = Atom.create_node(
      site_id: @site.id,
      type_name: 'ConceptNode',
      name: 'test'
    )
    
    atom.set_av(sti: 100.0, lti: 50.0)
    atom.save
    
    av = atom.av
    assert_equal 100.0, av[:sti]
    assert_equal 50.0, av[:lti]
  end

  it 'finds incoming links' do
    node = Atom.create_node(site_id: @site.id, type_name: 'ConceptNode', name: 'target')
    other_node = Atom.create_node(site_id: @site.id, type_name: 'ConceptNode', name: 'source')
    
    link = Atom.create_link(
      site_id: @site.id,
      type_name: 'InheritanceLink',
      outgoing: [other_node.id, node.id]
    )
    
    incoming = node.incoming
    assert_equal 1, incoming.length
    assert_equal link.id, incoming[0].id
  end

  it 'converts to string representation' do
    node = Atom.create_node(site_id: @site.id, type_name: 'ConceptNode', name: 'Alice')
    assert_equal '(ConceptNode "Alice")', node.to_s
    
    node2 = Atom.create_node(site_id: @site.id, type_name: 'ConceptNode', name: 'Bob')
    link = Atom.create_link(
      site_id: @site.id,
      type_name: 'SimilarityLink',
      outgoing: [node.id, node2.id]
    )
    
    assert_equal '(SimilarityLink (ConceptNode "Alice") (ConceptNode "Bob"))', link.to_s
  end

  it 'performs pattern matching' do
    Atom.create_node(site_id: @site.id, type_name: 'ConceptNode', name: 'Alice')
    Atom.create_node(site_id: @site.id, type_name: 'ConceptNode', name: 'Bob')
    Atom.create_node(site_id: @site.id, type_name: 'PredicateNode', name: 'likes')
    
    matches = Atom.pattern_match(site_id: @site.id, pattern: { type_name: 'ConceptNode' })
    assert_equal 2, matches.length
    
    matches = Atom.pattern_match(site_id: @site.id, pattern: { name: 'Alice' })
    assert_equal 1, matches.length
    assert_equal 'Alice', matches[0].name
  end
end

describe 'AtomSpace' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    DB[:atoms].delete
    DB[:atom_links].delete
    DB[:atomspace_shares].delete
    @site = Fabricate(:site)
    @atomspace = AtomSpace.new(@site.id)
  end

  it 'adds nodes to atomspace' do
    node = @atomspace.add_node('ConceptNode', 'Alice')
    
    assert node.persisted?
    assert_equal @site.id, node.site_id
    assert_equal 'Alice', node.name
  end

  it 'adds links to atomspace' do
    node1 = @atomspace.add_node('ConceptNode', 'Alice')
    node2 = @atomspace.add_node('ConceptNode', 'Bob')
    
    link = @atomspace.add_link('SimilarityLink', [node1.id, node2.id])
    
    assert link.persisted?
    assert_equal @site.id, link.site_id
    assert_equal 2, link.outgoing.length
  end

  it 'creates knowledge triples' do
    link = @atomspace.add_triple('Alice', 'knows', 'Bob')
    
    assert link.persisted?
    assert_equal 'EvaluationLink', link.type_name
    
    # Verify the structure
    outgoing = link.outgoing
    assert_equal 2, outgoing.length
    
    predicate = outgoing[0]
    assert_equal 'PredicateNode', predicate.type_name
    assert_equal 'knows', predicate.name
    
    list_link = outgoing[1]
    assert_equal 'ListLink', list_link.type_name
    
    list_outgoing = list_link.outgoing
    assert_equal 2, list_outgoing.length
    assert_equal 'Alice', list_outgoing[0].name
    assert_equal 'Bob', list_outgoing[1].name
  end

  it 'queries knowledge triples' do
    @atomspace.add_triple('Alice', 'knows', 'Bob')
    @atomspace.add_triple('Alice', 'likes', 'Pizza')
    @atomspace.add_triple('Bob', 'knows', 'Charlie')
    
    results = @atomspace.query_subject('Alice')
    
    assert_equal 2, results.length
    
    knows_triple = results.find { |t| t[:predicate] == 'knows' }
    assert_equal 'Alice', knows_triple[:subject]
    assert_equal 'knows', knows_triple[:predicate]
    assert_equal 'Bob', knows_triple[:object]
    
    likes_triple = results.find { |t| t[:predicate] == 'likes' }
    assert_equal 'Alice', likes_triple[:subject]
    assert_equal 'likes', likes_triple[:predicate]
    assert_equal 'Pizza', likes_triple[:object]
  end

  it 'gets atomspace statistics' do
    @atomspace.add_node('ConceptNode', 'Alice')
    @atomspace.add_node('ConceptNode', 'Bob')
    @atomspace.add_triple('Alice', 'knows', 'Bob')
    
    stats = @atomspace.stats
    
    assert stats[:total_atoms] >= 5  # At least: 2 concepts + predicate + list link + eval link
    assert stats[:node_count] >= 3
    assert stats[:link_count] >= 2
    assert stats[:type_distribution]['ConceptNode'] >= 2
  end

  it 'shares atoms between sites' do
    other_site = Fabricate(:site)
    
    node = @atomspace.add_node('ConceptNode', 'SharedKnowledge')
    
    share = @atomspace.share_atom(node.id, other_site.id, share_type: 'read')
    
    assert share.persisted?
    assert_equal @site.id, share.source_site_id
    assert_equal other_site.id, share.target_site_id
    assert_equal node.id, share.atom_id
  end

  it 'gets shared atoms' do
    other_site = Fabricate(:site)
    other_atomspace = AtomSpace.new(other_site.id)
    
    node = other_atomspace.add_node('ConceptNode', 'SharedKnowledge')
    other_atomspace.share_atom(node.id, @site.id)
    
    shared_atoms = @atomspace.get_shared_atoms(source_site_id: other_site.id)
    
    assert_equal 1, shared_atoms.length
    assert_equal 'SharedKnowledge', shared_atoms[0].name
  end

  it 'exports and imports atomspace' do
    @atomspace.add_node('ConceptNode', 'Alice')
    @atomspace.add_node('ConceptNode', 'Bob')
    @atomspace.add_triple('Alice', 'knows', 'Bob')
    
    export_json = @atomspace.export_json
    
    assert export_json.include?('Alice')
    assert export_json.include?('Bob')
    assert export_json.include?('knows')
    
    # Create new site and import
    new_site = Fabricate(:site)
    new_atomspace = AtomSpace.new(new_site.id)
    
    imported_count = new_atomspace.import_json(export_json)
    
    assert imported_count > 0
    
    # Verify import
    new_stats = new_atomspace.stats
    assert new_stats[:total_atoms] > 0
  end
end
