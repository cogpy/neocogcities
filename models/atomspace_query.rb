# frozen_string_literal: true
require 'json'

# AtomspaceQuery stores query patterns and results for caching and history
class AtomspaceQuery < Sequel::Model
  many_to_one :site
  
  def before_create
    self.created_at = Time.now
    super
  end
  
  def parsed_query_pattern
    return nil if query_pattern.nil?
    JSON.parse(query_pattern) rescue nil
  end
  
  def set_query_pattern(pattern)
    self.query_pattern = pattern.is_a?(String) ? pattern : pattern.to_json
  end
  
  def parsed_result
    return nil if result.nil?
    JSON.parse(result) rescue nil
  end
  
  def set_result(res)
    self.result = res.is_a?(String) ? res : res.to_json
    self.executed_at = Time.now
  end
  
  # Execute the query and cache results
  def execute!
    pattern = parsed_query_pattern
    return nil unless pattern
    
    matches = Atom.pattern_match(site_id: site_id, pattern: pattern)
    set_result(matches.map(&:to_hash))
    save
    
    parsed_result
  end
end
