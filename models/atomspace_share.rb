# frozen_string_literal: true

# AtomspaceShare represents sharing of atoms between different agents/sites
# Enables distributed cognition by allowing agents to share knowledge
class AtomspaceShare < Sequel::Model
  many_to_one :source_site, class: :Site, key: :source_site_id
  many_to_one :target_site, class: :Site, key: :target_site_id
  many_to_one :atom
  
  SHARE_TYPES = %w[read write copy].freeze
  
  def validate
    super
    errors.add(:share_type, 'must be read, write, or copy') unless SHARE_TYPES.include?(share_type)
    errors.add(:source_site_id, 'cannot equal target_site_id') if source_site_id == target_site_id
  end
  
  def before_create
    self.created_at = Time.now
    super
  end
  
  # Check if target site can read this atom
  def can_read?
    %w[read write copy].include?(share_type)
  end
  
  # Check if target site can modify this atom
  def can_write?
    share_type == 'write'
  end
  
  # Copy the atom to target site's atomspace
  def copy_to_target!
    return unless share_type == 'copy'
    
    # Create a copy of the atom in the target site's atomspace
    new_atom_attrs = atom.values.reject { |k, _| [:id, :site_id].include?(k) }
    new_atom_attrs[:site_id] = target_site_id
    
    new_atom = Atom.create(new_atom_attrs)
    
    # If it's a link, also copy the link structure
    if atom.link?
      atom.outgoing_links.each do |atom_link|
        AtomLink.create(
          link_id: new_atom.id,
          target_id: atom_link.target_id,
          position: atom_link.position
        )
      end
    end
    
    new_atom
  end
end
