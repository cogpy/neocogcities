# frozen_string_literal: true
require 'json'

# AtomSpace is the main interface for managing an agent's knowledge base
# It provides methods for creating, querying, and manipulating atoms in a hypergraph structure
class AtomSpace
  attr_reader :site_id
  
  def initialize(site_id)
    @site_id = site_id
  end
  
  # Create a new node
  def add_node(type_name, name, value: nil, tv: nil)
    Atom.find_or_create_node(
      site_id: site_id,
      type_name: type_name,
      name: name,
      value: value,
      tv: tv
    )
  end
  
  # Create a new link
  def add_link(type_name, outgoing, tv: nil)
    # Ensure all outgoing are atom IDs
    outgoing_ids = outgoing.map { |a| a.is_a?(Atom) ? a.id : a.to_i }
    
    # Check if link already exists
    existing = find_link(type_name, outgoing_ids)
    return existing if existing
    
    Atom.create_link(
      site_id: site_id,
      type_name: type_name,
      outgoing: outgoing_ids,
      tv: tv
    )
  end
  
  # Find a link with specific outgoing atoms
  def find_link(type_name, outgoing_ids)
    links = Atom.where(
      site_id: site_id,
      atom_type: 'link',
      type_name: type_name
    ).all
    
    links.find do |link|
      link_outgoing = link.outgoing.map(&:id)
      link_outgoing == outgoing_ids
    end
  end
  
  # Get atom by ID
  def get_atom(atom_id)
    atom = Atom[atom_id]
    return nil unless atom
    return nil unless atom.site_id == site_id
    atom
  end
  
  # Get all atoms
  def get_atoms(type: nil, limit: 1000, offset: 0)
    atoms = Atom.where(site_id: site_id)
    atoms = atoms.where(type_name: type) if type
    atoms.limit(limit).offset(offset).all
  end
  
  # Pattern matching query
  def query(pattern)
    Atom.pattern_match(site_id: site_id, pattern: pattern)
  end
  
  # Delete an atom
  def delete_atom(atom_id)
    atom = get_atom(atom_id)
    return false unless atom
    atom.destroy
    true
  end
  
  # Get incoming set (links pointing to this atom)
  def get_incoming(atom_id)
    atom = get_atom(atom_id)
    return [] unless atom
    atom.incoming
  end
  
  # Get outgoing set (atoms this link points to)
  def get_outgoing(atom_id)
    atom = get_atom(atom_id)
    return [] unless atom
    atom.outgoing
  end
  
  # Update truth value
  def set_tv(atom_id, strength:, confidence:)
    atom = get_atom(atom_id)
    return false unless atom
    atom.set_tv(strength: strength, confidence: confidence)
    atom.save
    true
  end
  
  # Update attention value
  def set_av(atom_id, sti:, lti:)
    atom = get_atom(atom_id)
    return false unless atom
    atom.set_av(sti: sti, lti: lti)
    atom.save
    true
  end
  
  # Share atom with another agent
  def share_atom(atom_id, target_site_id, share_type: 'read', is_public: false)
    atom = get_atom(atom_id)
    return nil unless atom
    
    AtomspaceShare.create(
      source_site_id: site_id,
      target_site_id: target_site_id,
      atom_id: atom_id,
      share_type: share_type,
      is_public: is_public
    )
  end
  
  # Get atoms shared with this agent
  def get_shared_atoms(source_site_id: nil)
    shares = AtomspaceShare.where(target_site_id: site_id)
    shares = shares.where(source_site_id: source_site_id) if source_site_id
    shares.map(&:atom)
  end
  
  # Get public atoms from all agents
  def get_public_atoms(limit: 100)
    shares = AtomspaceShare.where(is_public: true).limit(limit)
    shares.map(&:atom)
  end
  
  # Export atomspace to JSON
  def export_json
    atoms = get_atoms(limit: 100000)
    {
      site_id: site_id,
      atom_count: atoms.length,
      atoms: atoms.map(&:to_hash)
    }.to_json
  end
  
  # Import atoms from JSON
  def import_json(json_data)
    data = JSON.parse(json_data)
    imported_count = 0
    
    DB.transaction do
      data['atoms'].each do |atom_data|
        if atom_data['atom_type'] == 'node'
          add_node(
            atom_data['type_name'],
            atom_data['name'],
            value: atom_data['value'],
            tv: atom_data['tv']
          )
          imported_count += 1
        end
      end
      
      # Import links in a second pass (after all nodes exist)
      data['atoms'].select { |a| a['atom_type'] == 'link' }.each do |atom_data|
        if atom_data['outgoing']
          add_link(
            atom_data['type_name'],
            atom_data['outgoing'],
            tv: atom_data['tv']
          )
          imported_count += 1
        end
      end
    end
    
    imported_count
  end
  
  # Get statistics about the atomspace
  def stats
    total = Atom.where(site_id: site_id).count
    nodes = Atom.where(site_id: site_id, atom_type: 'node').count
    links = Atom.where(site_id: site_id, atom_type: 'link').count
    
    type_counts = Atom
      .where(site_id: site_id)
      .group_and_count(:type_name)
      .order(Sequel.desc(:count))
      .all
      .map { |r| [r[:type_name], r[:count]] }
      .to_h
    
    {
      total_atoms: total,
      node_count: nodes,
      link_count: links,
      type_distribution: type_counts,
      shared_out: AtomspaceShare.where(source_site_id: site_id).count,
      shared_in: AtomspaceShare.where(target_site_id: site_id).count
    }
  end
  
  # Create a simple knowledge triple: subject-predicate-object
  def add_triple(subject_name, predicate_name, object_name)
    subject = add_node('ConceptNode', subject_name)
    predicate = add_node('PredicateNode', predicate_name)
    object = add_node('ConceptNode', object_name)
    
    # Create EvaluationLink: (EvaluationLink predicate (ListLink subject object))
    list_link = add_link('ListLink', [subject.id, object.id])
    add_link('EvaluationLink', [predicate.id, list_link.id])
  end
  
  # Query triples: find all facts about a subject
  def query_subject(subject_name)
    subject_node = Atom.where(
      site_id: site_id,
      atom_type: 'node',
      type_name: 'ConceptNode',
      name: subject_name
    ).first
    
    return [] unless subject_node
    
    # Find all EvaluationLinks containing this subject
    results = []
    subject_node.incoming.each do |list_link|
      next unless list_link.type_name == 'ListLink'
      
      list_link.incoming.each do |eval_link|
        next unless eval_link.type_name == 'EvaluationLink'
        
        outgoing = eval_link.outgoing
        if outgoing.length == 2
          predicate = outgoing[0]
          list = outgoing[1]
          
          if list.outgoing.length == 2
            obj = list.outgoing[1]
            results << {
              subject: subject_name,
              predicate: predicate.name,
              object: obj.name
            }
          end
        end
      end
    end
    
    results
  end
end
