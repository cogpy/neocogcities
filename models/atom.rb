# frozen_string_literal: true
require 'json'

# Atom is the basic unit in the AtomSpace knowledge representation system
# It can be either a Node (atomic concept) or Link (relationship between atoms)
class Atom < Sequel::Model
  many_to_one :site
  
  # For link atoms, these are the outgoing atoms (targets)
  one_to_many :outgoing_links, class: :AtomLink, key: :link_id
  
  # For any atom, these are the links that point to this atom
  one_to_many :incoming_links, class: :AtomLink, key: :target_id
  
  one_to_many :shares, class: :AtomspaceShare, key: :atom_id
  
  # Atom types
  ATOM_TYPES = {
    node: %w[
      ConceptNode
      PredicateNode
      VariableNode
      NumberNode
      TypeNode
      GroundedSchemaNode
      ContextNode
      AgentNode
    ],
    link: %w[
      InheritanceLink
      SimilarityLink
      MemberLink
      EvaluationLink
      ImplicationLink
      ListLink
      AndLink
      OrLink
      NotLink
      ExecutionLink
      AtTimeLink
    ]
  }.freeze
  
  def validate
    super
    errors.add(:atom_type, 'must be node or link') unless %w[node link].include?(atom_type)
    errors.add(:type_name, 'is not a valid type') unless valid_type_name?
    errors.add(:site_id, 'is required') unless site_id
    
    if atom_type == 'node'
      errors.add(:name, 'is required for nodes') if name.nil? || name.strip.empty?
    end
  end
  
  def before_create
    self.created_at = Time.now
    self.updated_at = Time.now
    super
  end
  
  def before_update
    self.updated_at = Time.now
    super
  end
  
  def valid_type_name?
    ATOM_TYPES[:node].include?(type_name) || ATOM_TYPES[:link].include?(type_name)
  end
  
  def node?
    atom_type == 'node'
  end
  
  def link?
    atom_type == 'link'
  end
  
  # Get the atoms that this link points to (for link atoms)
  def outgoing
    return [] unless link?
    outgoing_links_dataset.order(:position).map { |al| Atom[al.target_id] }.compact
  end
  
  # Get the links that point to this atom
  def incoming
    incoming_links_dataset.map { |al| Atom[al.link_id] }.compact
  end
  
  # Parse value from JSON
  def parsed_value
    return nil if value.nil?
    JSON.parse(value) rescue value
  end
  
  # Set value as JSON
  def set_value(val)
    self.value = val.is_a?(String) ? val : val.to_json
  end
  
  # Truth value
  def tv
    { strength: truth_value_strength, confidence: truth_value_confidence }
  end
  
  def set_tv(strength:, confidence:)
    self.truth_value_strength = strength.to_f.clamp(0.0, 1.0)
    self.truth_value_confidence = confidence.to_f.clamp(0.0, 1.0)
  end
  
  # Attention value
  def av
    { sti: attention_value_sti, lti: attention_value_lti }
  end
  
  def set_av(sti:, lti:)
    self.attention_value_sti = sti.to_f
    self.attention_value_lti = lti.to_f
  end
  
  # Convert to hash representation
  def to_hash
    {
      id: id,
      atom_type: atom_type,
      type_name: type_name,
      name: name,
      value: parsed_value,
      tv: tv,
      av: av,
      outgoing: link? ? outgoing.map(&:id) : nil,
      created_at: created_at,
      updated_at: updated_at
    }.compact
  end
  
  # String representation similar to OpenCog format
  def to_s
    if node?
      "(#{type_name} \"#{name}\")"
    else
      outgoing_str = outgoing.map(&:to_s).join(' ')
      "(#{type_name} #{outgoing_str})"
    end
  end
  
  # Create a node atom
  def self.create_node(site_id:, type_name:, name:, value: nil, tv: nil)
    raise ArgumentError, "Invalid node type: #{type_name}" unless ATOM_TYPES[:node].include?(type_name)
    
    atom = create(
      site_id: site_id,
      atom_type: 'node',
      type_name: type_name,
      name: name
    )
    
    atom.set_value(value) if value
    atom.set_tv(**tv) if tv
    atom.save
    atom
  end
  
  # Create a link atom
  def self.create_link(site_id:, type_name:, outgoing:, tv: nil)
    raise ArgumentError, "Invalid link type: #{type_name}" unless ATOM_TYPES[:link].include?(type_name)
    raise ArgumentError, "Outgoing must be an array" unless outgoing.is_a?(Array)
    raise ArgumentError, "Outgoing cannot be empty" if outgoing.empty?
    
    DB.transaction do
      link = create(
        site_id: site_id,
        atom_type: 'link',
        type_name: type_name
      )
      
      outgoing.each_with_index do |target_atom_id, position|
        AtomLink.create(
          link_id: link.id,
          target_id: target_atom_id,
          position: position
        )
      end
      
      link.set_tv(**tv) if tv
      link.save
      link
    end
  end
  
  # Find or create a node
  def self.find_or_create_node(site_id:, type_name:, name:, value: nil, tv: nil)
    existing = where(site_id: site_id, atom_type: 'node', type_name: type_name, name: name).first
    return existing if existing
    
    create_node(site_id: site_id, type_name: type_name, name: name, value: value, tv: tv)
  end
  
  # Pattern matching for queries
  def self.pattern_match(site_id:, pattern:)
    # Basic pattern matching implementation
    # Pattern format: { type_name: 'ConceptNode', name: 'something' } or more complex
    atoms = where(site_id: site_id)
    
    if pattern[:atom_type]
      atoms = atoms.where(atom_type: pattern[:atom_type])
    end
    
    if pattern[:type_name]
      atoms = atoms.where(type_name: pattern[:type_name])
    end
    
    if pattern[:name]
      if pattern[:name].is_a?(Regexp)
        atoms = atoms.where(Sequel.like(:name, pattern[:name]))
      else
        atoms = atoms.where(name: pattern[:name])
      end
    end
    
    atoms.all
  end
end
