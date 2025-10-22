# frozen_string_literal: true

# AtomLink represents the connection between a link atom and its target atoms
# This allows links to have multiple outgoing connections in a specific order
class AtomLink < Sequel::Model
  many_to_one :link, class: :Atom, key: :link_id
  many_to_one :target, class: :Atom, key: :target_id
  
  def before_create
    self.created_at = Time.now
    super
  end
end
