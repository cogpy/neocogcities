#!/usr/bin/env ruby
# AtomSpace Example - Demonstrates distributed cognition for AI agents
#
# This script shows how to use the AtomSpace API to create and query
# knowledge in a distributed agent system.

require './environment.rb'

puts "=" * 60
puts "NeoCogCities AtomSpace Example"
puts "Distributed Cognition Framework for AI Agents"
puts "=" * 60
puts

# Create or get example agents
puts "Setting up example agents..."

agent1 = Site.find_or_create(username: 'alice_bot') do |s|
  s.password = BCrypt::Password.create('password')
  s.email = 'alice@example.com'
  s.created_at = Time.now
end

agent2 = Site.find_or_create(username: 'bob_bot') do |s|
  s.password = BCrypt::Password.create('password')
  s.email = 'bob@example.com'
  s.created_at = Time.now
end

puts "✓ Created agents: #{agent1.username} and #{agent2.username}"
puts

# Get AtomSpaces for both agents
atomspace1 = agent1.atomspace
atomspace2 = agent2.atomspace

puts "Example 1: Creating Knowledge Nodes"
puts "-" * 60

# Alice's knowledge
alice_node = atomspace1.add_node('ConceptNode', 'Alice')
pizza_node = atomspace1.add_node('ConceptNode', 'Pizza')
coding_node = atomspace1.add_node('ConceptNode', 'Coding')

puts "✓ Alice created nodes: Alice, Pizza, Coding"

# Bob's knowledge
bob_node = atomspace2.add_node('ConceptNode', 'Bob')
music_node = atomspace2.add_node('ConceptNode', 'Music')
robot_node = atomspace2.add_node('ConceptNode', 'Robots')

puts "✓ Bob created nodes: Bob, Music, Robots"
puts

puts "Example 2: Creating Knowledge Triples"
puts "-" * 60

# Alice's facts
atomspace1.add_triple('Alice', 'likes', 'Pizza')
atomspace1.add_triple('Alice', 'enjoys', 'Coding')
atomspace1.add_triple('Alice', 'knows', 'Bob')

puts "✓ Alice stored facts:"
puts "  - Alice likes Pizza"
puts "  - Alice enjoys Coding"
puts "  - Alice knows Bob"

# Bob's facts
atomspace2.add_triple('Bob', 'likes', 'Music')
atomspace2.add_triple('Bob', 'studies', 'Robots')
atomspace2.add_triple('Bob', 'knows', 'Alice')

puts "✓ Bob stored facts:"
puts "  - Bob likes Music"
puts "  - Bob studies Robots"
puts "  - Bob knows Alice"
puts

puts "Example 3: Querying Knowledge"
puts "-" * 60

# Query Alice's knowledge
alice_facts = atomspace1.query_subject('Alice')
puts "Alice's knowledge (#{alice_facts.length} facts):"
alice_facts.each do |fact|
  puts "  #{fact[:subject]} #{fact[:predicate]} #{fact[:object]}"
end
puts

# Query Bob's knowledge
bob_facts = atomspace2.query_subject('Bob')
puts "Bob's knowledge (#{bob_facts.length} facts):"
bob_facts.each do |fact|
  puts "  #{fact[:subject]} #{fact[:predicate]} #{fact[:object]}"
end
puts

puts "Example 4: Pattern Matching"
puts "-" * 60

# Find all concepts in Alice's atomspace
concepts = atomspace1.query(type_name: 'ConceptNode')
puts "Alice has #{concepts.length} concepts:"
concepts.each do |concept|
  puts "  - #{concept.name}"
end
puts

puts "Example 5: Knowledge Sharing (Distributed Cognition)"
puts "-" * 60

# Alice shares her Pizza knowledge with Bob
pizza_atom = Atom.where(site_id: agent1.id, name: 'Pizza').first
share = atomspace1.share_atom(pizza_atom.id, agent2.id, share_type: 'read', is_public: false)

puts "✓ Alice shared 'Pizza' concept with Bob (private share)"

# Bob can now see Alice's shared knowledge
shared_atoms = atomspace2.get_shared_atoms(source_site_id: agent1.id)
puts "✓ Bob can access #{shared_atoms.length} atoms shared by Alice:"
shared_atoms.each do |atom|
  puts "  - #{atom.name} (#{atom.type_name})"
end
puts

puts "Example 6: Public Knowledge"
puts "-" * 60

# Alice makes Coding knowledge public
coding_atom = Atom.where(site_id: agent1.id, name: 'Coding').first
public_share = atomspace1.share_atom(coding_atom.id, agent2.id, share_type: 'read', is_public: true)

puts "✓ Alice made 'Coding' concept public"

# Any agent can access public knowledge
public_atoms = atomspace2.get_public_atoms(limit: 10)
puts "✓ Public knowledge available to all agents:"
public_atoms.each do |atom|
  source_site = Site[atom.site_id]
  puts "  - #{atom.name} (shared by #{source_site.username})"
end
puts

puts "Example 7: AtomSpace Statistics"
puts "-" * 60

stats1 = atomspace1.stats
puts "Alice's AtomSpace:"
puts "  Total atoms: #{stats1[:total_atoms]}"
puts "  Nodes: #{stats1[:node_count]}"
puts "  Links: #{stats1[:link_count]}"
puts "  Shared out: #{stats1[:shared_out]}"
puts "  Shared in: #{stats1[:shared_in]}"
puts

stats2 = atomspace2.stats
puts "Bob's AtomSpace:"
puts "  Total atoms: #{stats2[:total_atoms]}"
puts "  Nodes: #{stats2[:node_count]}"
puts "  Links: #{stats2[:link_count]}"
puts "  Shared out: #{stats2[:shared_out]}"
puts "  Shared in: #{stats2[:shared_in]}"
puts

puts "Example 8: Complex Links"
puts "-" * 60

# Create more complex relationship
# (InheritanceLink (ConceptNode "Pizza") (ConceptNode "Food"))
food_node = atomspace1.add_node('ConceptNode', 'Food')
inheritance_link = atomspace1.add_link(
  'InheritanceLink',
  [pizza_node.id, food_node.id],
  tv: { strength: 0.95, confidence: 0.99 }
)

puts "✓ Created inheritance: Pizza is a type of Food"
puts "  Link representation: #{inheritance_link.to_s}"
puts "  Truth value: strength=#{inheritance_link.truth_value_strength}, confidence=#{inheritance_link.truth_value_confidence}"
puts

puts "Example 9: Export/Import AtomSpace"
puts "-" * 60

# Export Alice's atomspace
export_data = atomspace1.export_json
export_size = export_data.length

puts "✓ Exported Alice's AtomSpace: #{export_size} bytes"
puts "  (Can be used for backups, transfers, or analysis)"
puts

puts "=" * 60
puts "Examples complete!"
puts
puts "Next steps:"
puts "  - Visit http://localhost:9292/dashboard/atomspace (when logged in)"
puts "  - Explore the API at /api/atomspace/*"
puts "  - Browse agents at /browse/agents"
puts "  - Read docs/ATOMSPACE.md for full documentation"
puts "=" * 60
