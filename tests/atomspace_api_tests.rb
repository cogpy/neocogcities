require_relative './environment.rb'

describe 'AtomSpace API' do
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

  describe 'GET /api/atomspace/info' do
    it 'returns atomspace info when logged in' do
      post '/signin', username: @site.username, password: 'derp'
      
      get '/api/atomspace/info'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert_equal @site.id, result['info']['site_id']
      assert_equal @site.username, result['info']['username']
      assert result['info']['stats']
    end

    it 'requires login' do
      get '/api/atomspace/info'
      # Should redirect or fail without login
      refute last_response.ok?
    end
  end

  describe 'POST /api/atomspace/nodes' do
    it 'creates a new node' do
      post '/signin', username: @site.username, password: 'derp'
      
      post '/api/atomspace/nodes', {
        type_name: 'ConceptNode',
        name: 'TestConcept',
        value: { test: 'data' }
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert result['atom']
      assert_equal 'ConceptNode', result['atom']['type_name']
      assert_equal 'TestConcept', result['atom']['name']
    end

    it 'creates a node with truth value' do
      post '/signin', username: @site.username, password: 'derp'
      
      post '/api/atomspace/nodes', {
        type_name: 'ConceptNode',
        name: 'TestConcept',
        tv: { strength: 0.8, confidence: 0.9 }
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert_equal 0.8, result['atom']['tv']['strength']
      assert_equal 0.9, result['atom']['tv']['confidence']
    end

    it 'returns error for missing fields' do
      post '/signin', username: @site.username, password: 'derp'
      
      post '/api/atomspace/nodes', {
        type_name: 'ConceptNode'
        # name is missing
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      
      result = JSON.parse(last_response.body)
      assert_equal 'error', result['result']
      assert_equal 'missing_fields', result['error_type']
    end
  end

  describe 'POST /api/atomspace/links' do
    it 'creates a new link' do
      post '/signin', username: @site.username, password: 'derp'
      
      # Create nodes first
      node1 = @atomspace.add_node('ConceptNode', 'Alice')
      node2 = @atomspace.add_node('ConceptNode', 'Bob')
      
      post '/api/atomspace/links', {
        type_name: 'SimilarityLink',
        outgoing: [node1.id, node2.id]
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert_equal 'SimilarityLink', result['atom']['type_name']
      assert_equal [node1.id, node2.id], result['atom']['outgoing']
    end
  end

  describe 'POST /api/atomspace/triples' do
    it 'creates a knowledge triple' do
      post '/signin', username: @site.username, password: 'derp'
      
      post '/api/atomspace/triples', {
        subject: 'Alice',
        predicate: 'knows',
        object: 'Bob'
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert result['link']
    end
  end

  describe 'GET /api/atomspace/triples/:subject' do
    it 'queries triples by subject' do
      post '/signin', username: @site.username, password: 'derp'
      
      @atomspace.add_triple('Alice', 'knows', 'Bob')
      @atomspace.add_triple('Alice', 'likes', 'Pizza')
      
      get '/api/atomspace/triples/Alice'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert_equal 2, result['count']
      assert_equal 2, result['triples'].length
    end
  end

  describe 'POST /api/atomspace/query' do
    it 'queries atoms by pattern' do
      post '/signin', username: @site.username, password: 'derp'
      
      @atomspace.add_node('ConceptNode', 'Alice')
      @atomspace.add_node('ConceptNode', 'Bob')
      @atomspace.add_node('PredicateNode', 'knows')
      
      post '/api/atomspace/query', {
        pattern: { type_name: 'ConceptNode' }
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert_equal 2, result['count']
    end
  end

  describe 'GET /api/atomspace/atoms' do
    it 'lists atoms' do
      post '/signin', username: @site.username, password: 'derp'
      
      @atomspace.add_node('ConceptNode', 'Alice')
      @atomspace.add_node('ConceptNode', 'Bob')
      
      get '/api/atomspace/atoms'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert result['count'] >= 2
      assert result['atoms'].is_a?(Array)
    end

    it 'filters atoms by type' do
      post '/signin', username: @site.username, password: 'derp'
      
      @atomspace.add_node('ConceptNode', 'Alice')
      @atomspace.add_node('PredicateNode', 'knows')
      
      get '/api/atomspace/atoms', type: 'ConceptNode'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 1, result['count']
      assert_equal 'ConceptNode', result['atoms'][0]['type_name']
    end
  end

  describe 'GET /api/atomspace/atoms/:id' do
    it 'gets a specific atom' do
      post '/signin', username: @site.username, password: 'derp'
      
      node = @atomspace.add_node('ConceptNode', 'Alice')
      
      get "/api/atomspace/atoms/#{node.id}"
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert_equal node.id, result['atom']['id']
      assert_equal 'Alice', result['atom']['name']
    end

    it 'returns error for non-existent atom' do
      post '/signin', username: @site.username, password: 'derp'
      
      get '/api/atomspace/atoms/999999'
      
      result = JSON.parse(last_response.body)
      assert_equal 'error', result['result']
      assert_equal 'not_found', result['error_type']
    end
  end

  describe 'DELETE /api/atomspace/atoms/:id' do
    it 'deletes an atom' do
      post '/signin', username: @site.username, password: 'derp'
      
      node = @atomspace.add_node('ConceptNode', 'Alice')
      
      delete "/api/atomspace/atoms/#{node.id}"
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      
      # Verify deletion
      assert_nil Atom[node.id]
    end
  end

  describe 'POST /api/atomspace/share' do
    it 'shares an atom with another site' do
      post '/signin', username: @site.username, password: 'derp'
      
      other_site = Fabricate(:site)
      node = @atomspace.add_node('ConceptNode', 'SharedKnowledge')
      
      post '/api/atomspace/share', {
        atom_id: node.id,
        target_site_id: other_site.id,
        share_type: 'read'
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert result['share_id']
    end
  end

  describe 'GET /api/atomspace/shared' do
    it 'gets shared atoms' do
      post '/signin', username: @site.username, password: 'derp'
      
      other_site = Fabricate(:site)
      other_atomspace = AtomSpace.new(other_site.id)
      
      node = other_atomspace.add_node('ConceptNode', 'SharedKnowledge')
      other_atomspace.share_atom(node.id, @site.id)
      
      get '/api/atomspace/shared'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert_equal 1, result['count']
    end
  end

  describe 'GET /api/atomspace/export' do
    it 'exports atomspace as JSON' do
      post '/signin', username: @site.username, password: 'derp'
      
      @atomspace.add_node('ConceptNode', 'Alice')
      @atomspace.add_triple('Alice', 'knows', 'Bob')
      
      get '/api/atomspace/export'
      
      assert last_response.ok?
      assert_equal 'application/json', last_response.content_type
      
      result = JSON.parse(last_response.body)
      assert_equal @site.id, result['site_id']
      assert result['atoms'].is_a?(Array)
      assert result['atoms'].length > 0
    end
  end

  describe 'POST /api/atomspace/import' do
    it 'imports atomspace from JSON' do
      post '/signin', username: @site.username, password: 'derp'
      
      # Create export data
      export_data = {
        atoms: [
          {
            atom_type: 'node',
            type_name: 'ConceptNode',
            name: 'ImportedConcept'
          }
        ]
      }
      
      post '/api/atomspace/import', export_data.to_json, 'CONTENT_TYPE' => 'application/json'
      
      assert last_response.ok?
      
      result = JSON.parse(last_response.body)
      assert_equal 'success', result['result']
      assert result['imported_count'] > 0
    end
  end
end
