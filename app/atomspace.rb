get '/dashboard/atomspace' do
  require_login
  
  @title = 'AtomSpace - Agent Knowledge Base'
  @atomspace = current_site.atomspace
  @stats = @atomspace.stats
  
  # Get recent atoms
  @recent_atoms = current_site.atoms_dataset.order(Sequel.desc(:created_at)).limit(20).all
  
  # Get shared atoms
  @shared_in_count = current_site.shared_atoms_in_dataset.count
  @shared_out_count = current_site.shared_atoms_out_dataset.count
  
  erb :'dashboard/atomspace'
end

get '/dashboard/atomspace/atoms/:id' do
  require_login
  
  atom = current_site.atomspace.get_atom(params[:id].to_i)
  
  if atom
    @title = "Atom: #{atom.name || atom.id}"
    @atom = atom
    @incoming = atom.incoming
    @outgoing = atom.outgoing
    
    erb :'dashboard/atomspace_atom'
  else
    flash[:error] = 'Atom not found'
    redirect '/dashboard/atomspace'
  end
end

post '/dashboard/atomspace/nodes' do
  require_login
  
  type_name = params[:type_name]
  name = params[:name]
  value = params[:value]
  
  unless type_name && name
    flash[:error] = 'Type name and name are required'
    redirect '/dashboard/atomspace'
    return
  end
  
  begin
    atom = current_site.atomspace.add_node(type_name, name, value: value)
    flash[:success] = "Node created: #{atom.name}"
  rescue => e
    flash[:error] = "Error creating node: #{e.message}"
  end
  
  redirect '/dashboard/atomspace'
end

post '/dashboard/atomspace/triples' do
  require_login
  
  subject = params[:subject]
  predicate = params[:predicate]
  object = params[:object]
  
  unless subject && predicate && object
    flash[:error] = 'Subject, predicate, and object are required'
    redirect '/dashboard/atomspace'
    return
  end
  
  begin
    link = current_site.atomspace.add_triple(subject, predicate, object)
    flash[:success] = "Triple created: #{subject} - #{predicate} - #{object}"
  rescue => e
    flash[:error] = "Error creating triple: #{e.message}"
  end
  
  redirect '/dashboard/atomspace'
end

get '/dashboard/atomspace/query' do
  require_login
  
  @title = 'Query AtomSpace'
  
  if params[:type_name] || params[:name]
    pattern = {}
    pattern[:type_name] = params[:type_name] if params[:type_name] && !params[:type_name].empty?
    pattern[:name] = params[:name] if params[:name] && !params[:name].empty?
    
    @results = current_site.atomspace.query(pattern)
  end
  
  erb :'dashboard/atomspace_query'
end

get '/browse/agents' do
  @title = 'Browse Agents'
  
  # Find sites that are agents (have atoms)
  @agents = Site
    .select(:sites.*)
    .distinct
    .join(:atoms, site_id: :id)
    .where(is_deleted: false, is_banned: false)
    .order(Sequel.desc(:sites__updated_at))
    .limit(50)
    .all
  
  erb :'browse_agents'
end

get '/site/:username/atomspace' do
  @site = Site[username: params[:username]]
  
  if @site.nil?
    return not_found
  end
  
  if @site.is_deleted || @site.is_banned
    return not_found
  end
  
  @title = "#{@site.username}'s AtomSpace"
  @is_owner = current_site && current_site.id == @site.id
  @atomspace = @site.atomspace
  @stats = @atomspace.stats
  
  # Only show public atoms or if owner
  if @is_owner
    @atoms = @site.atoms_dataset.order(Sequel.desc(:created_at)).limit(100).all
  else
    # Show only public shared atoms
    public_shares = AtomspaceShare.where(source_site_id: @site.id, is_public: true).all
    @atoms = public_shares.map(&:atom)
  end
  
  erb :'site_atomspace'
end
