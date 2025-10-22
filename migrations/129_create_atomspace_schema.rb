Sequel.migration do
  change do
    create_table(:atoms) do
      primary_key :id
      Integer :site_id, null: false
      String :atom_type, null: false # 'node' or 'link'
      String :type_name, null: false # ConceptNode, InheritanceLink, etc.
      String :name # For nodes
      Text :value # JSON serialized data
      Float :truth_value_strength, default: 1.0
      Float :truth_value_confidence, default: 1.0
      Float :attention_value_sti, default: 0.0 # Short-term importance
      Float :attention_value_lti, default: 0.0 # Long-term importance
      DateTime :created_at
      DateTime :updated_at
      
      index :site_id
      index [:site_id, :atom_type]
      index [:site_id, :type_name]
      index [:site_id, :name]
    end
    
    create_table(:atom_links) do
      primary_key :id
      Integer :link_id, null: false
      Integer :target_id, null: false
      Integer :position, null: false, default: 0
      DateTime :created_at
      
      foreign_key [:link_id], :atoms, on_delete: :cascade
      foreign_key [:target_id], :atoms, on_delete: :cascade
      
      index [:link_id, :position]
      index :target_id
    end
    
    create_table(:atomspace_shares) do
      primary_key :id
      Integer :source_site_id, null: false
      Integer :target_site_id, null: false
      Integer :atom_id, null: false
      Boolean :is_public, default: false
      String :share_type, default: 'read' # read, write, copy
      DateTime :created_at
      
      foreign_key [:source_site_id], :sites, on_delete: :cascade
      foreign_key [:target_site_id], :sites, on_delete: :cascade
      foreign_key [:atom_id], :atoms, on_delete: :cascade
      
      index [:source_site_id, :target_site_id]
      index :atom_id
      index :is_public
    end
    
    create_table(:atomspace_queries) do
      primary_key :id
      Integer :site_id, null: false
      Text :query_pattern # JSON pattern for matching
      Text :result # JSON cached result
      DateTime :created_at
      DateTime :executed_at
      
      foreign_key [:site_id], :sites, on_delete: :cascade
      
      index :site_id
      index :executed_at
    end
  end
end
