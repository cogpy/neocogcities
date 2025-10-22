get '/api/atomspace/info' do
  require_login

  atomspace = current_site.atomspace
  
  {
    result: 'success',
    info: {
      site_id: current_site.id,
      username: current_site.username,
      stats: atomspace.stats,
      is_agent: current_site.agent?
    }
  }.to_json
end

get '/api/atomspace/atoms' do
  require_login
  
  type = params[:type]
  limit = (params[:limit] || 100).to_i.clamp(1, 1000)
  offset = (params[:offset] || 0).to_i
  
  atomspace = current_site.atomspace
  atoms = atomspace.get_atoms(type: type, limit: limit, offset: offset)
  
  {
    result: 'success',
    count: atoms.length,
    atoms: atoms.map(&:to_hash)
  }.to_json
end

get '/api/atomspace/atoms/:id' do
  require_login
  
  atom = current_site.atomspace.get_atom(params[:id].to_i)
  
  if atom
    {
      result: 'success',
      atom: atom.to_hash
    }.to_json
  else
    {
      result: 'error',
      error_type: 'not_found',
      message: 'Atom not found'
    }.to_json
  end
end

post '/api/atomspace/nodes' do
  require_login
  
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    return {
      result: 'error',
      error_type: 'invalid_json',
      message: 'Invalid JSON in request body'
    }.to_json
  end
  
  unless data['type_name'] && data['name']
    return {
      result: 'error',
      error_type: 'missing_fields',
      message: 'type_name and name are required'
    }.to_json
  end
  
  atomspace = current_site.atomspace
  
  tv = data['tv'] ? { strength: data['tv']['strength'], confidence: data['tv']['confidence'] } : nil
  
  atom = atomspace.add_node(
    data['type_name'],
    data['name'],
    value: data['value'],
    tv: tv
  )
  
  {
    result: 'success',
    atom: atom.to_hash
  }.to_json
end

post '/api/atomspace/links' do
  require_login
  
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    return {
      result: 'error',
      error_type: 'invalid_json',
      message: 'Invalid JSON in request body'
    }.to_json
  end
  
  unless data['type_name'] && data['outgoing']
    return {
      result: 'error',
      error_type: 'missing_fields',
      message: 'type_name and outgoing are required'
    }.to_json
  end
  
  atomspace = current_site.atomspace
  
  tv = data['tv'] ? { strength: data['tv']['strength'], confidence: data['tv']['confidence'] } : nil
  
  atom = atomspace.add_link(
    data['type_name'],
    data['outgoing'],
    tv: tv
  )
  
  {
    result: 'success',
    atom: atom.to_hash
  }.to_json
end

delete '/api/atomspace/atoms/:id' do
  require_login
  
  atomspace = current_site.atomspace
  
  if atomspace.delete_atom(params[:id].to_i)
    {
      result: 'success',
      message: 'Atom deleted'
    }.to_json
  else
    {
      result: 'error',
      error_type: 'not_found',
      message: 'Atom not found or could not be deleted'
    }.to_json
  end
end

post '/api/atomspace/query' do
  require_login
  
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    return {
      result: 'error',
      error_type: 'invalid_json',
      message: 'Invalid JSON in request body'
    }.to_json
  end
  
  unless data['pattern']
    return {
      result: 'error',
      error_type: 'missing_pattern',
      message: 'pattern is required'
    }.to_json
  end
  
  atomspace = current_site.atomspace
  pattern = data['pattern'].transform_keys(&:to_sym)
  
  matches = atomspace.query(pattern)
  
  {
    result: 'success',
    count: matches.length,
    matches: matches.map(&:to_hash)
  }.to_json
end

post '/api/atomspace/triples' do
  require_login
  
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    return {
      result: 'error',
      error_type: 'invalid_json',
      message: 'Invalid JSON in request body'
    }.to_json
  end
  
  unless data['subject'] && data['predicate'] && data['object']
    return {
      result: 'error',
      error_type: 'missing_fields',
      message: 'subject, predicate, and object are required'
    }.to_json
  end
  
  atomspace = current_site.atomspace
  link = atomspace.add_triple(data['subject'], data['predicate'], data['object'])
  
  {
    result: 'success',
    link: link.to_hash
  }.to_json
end

get '/api/atomspace/triples/:subject' do
  require_login
  
  atomspace = current_site.atomspace
  triples = atomspace.query_subject(params[:subject])
  
  {
    result: 'success',
    count: triples.length,
    triples: triples
  }.to_json
end

post '/api/atomspace/share' do
  require_login
  
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    return {
      result: 'error',
      error_type: 'invalid_json',
      message: 'Invalid JSON in request body'
    }.to_json
  end
  
  unless data['atom_id'] && data['target_site_id']
    return {
      result: 'error',
      error_type: 'missing_fields',
      message: 'atom_id and target_site_id are required'
    }.to_json
  end
  
  atomspace = current_site.atomspace
  
  share = atomspace.share_atom(
    data['atom_id'].to_i,
    data['target_site_id'].to_i,
    share_type: data['share_type'] || 'read',
    is_public: data['is_public'] || false
  )
  
  if share
    {
      result: 'success',
      share_id: share.id
    }.to_json
  else
    {
      result: 'error',
      error_type: 'share_failed',
      message: 'Could not create share'
    }.to_json
  end
end

get '/api/atomspace/shared' do
  require_login
  
  atomspace = current_site.atomspace
  source_site_id = params[:source_site_id]&.to_i
  
  shared_atoms = atomspace.get_shared_atoms(source_site_id: source_site_id)
  
  {
    result: 'success',
    count: shared_atoms.length,
    atoms: shared_atoms.map(&:to_hash)
  }.to_json
end

get '/api/atomspace/public' do
  require_login
  
  atomspace = current_site.atomspace
  limit = (params[:limit] || 100).to_i.clamp(1, 100)
  
  public_atoms = atomspace.get_public_atoms(limit: limit)
  
  {
    result: 'success',
    count: public_atoms.length,
    atoms: public_atoms.map(&:to_hash)
  }.to_json
end

get '/api/atomspace/export' do
  require_login
  
  atomspace = current_site.atomspace
  json_export = atomspace.export_json
  
  content_type 'application/json'
  attachment "atomspace_#{current_site.username}_#{Time.now.to_i}.json"
  json_export
end

post '/api/atomspace/import' do
  require_login
  
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    return {
      result: 'error',
      error_type: 'invalid_json',
      message: 'Invalid JSON in request body'
    }.to_json
  end
  
  atomspace = current_site.atomspace
  
  begin
    imported_count = atomspace.import_json(data.to_json)
    {
      result: 'success',
      imported_count: imported_count
    }.to_json
  rescue => e
    {
      result: 'error',
      error_type: 'import_failed',
      message: e.message
    }.to_json
  end
end
