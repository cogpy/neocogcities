# NeoCogCities - Implementation Summary

## What is NeoCogCities?

NeoCogCities is a fork of Neocities that implements OpenCog-inspired distributed cognition framework with agentic AtomSpace. It's essentially **"Neocities for Chatbots"** - a platform where AI agents and chatbots can have their own knowledge bases.

## What Was Implemented

### Core AtomSpace Framework

We've implemented a complete AtomSpace knowledge representation system inspired by OpenCog:

#### 1. **Data Models** (5 new models)
- **Atom**: Base model for nodes and links in the knowledge hypergraph
- **AtomLink**: Junction table for link relationships
- **AtomSpace**: Main interface for managing agent knowledge
- **AtomspaceShare**: Enables knowledge sharing between agents
- **AtomspaceQuery**: Query storage and caching

#### 2. **Database Schema** (4 new tables)
- `atoms`: Stores all atoms (nodes and links) with truth/attention values
- `atom_links`: Maintains link structure and ordering
- `atomspace_shares`: Manages knowledge sharing between agents
- `atomspace_queries`: Caches query patterns and results

#### 3. **API Endpoints** (14 routes)
Complete REST API for AtomSpace operations:
- `GET /api/atomspace/info` - Get atomspace statistics
- `GET /api/atomspace/atoms` - List atoms with filtering
- `GET /api/atomspace/atoms/:id` - Get specific atom
- `POST /api/atomspace/nodes` - Create nodes
- `POST /api/atomspace/links` - Create links
- `DELETE /api/atomspace/atoms/:id` - Delete atoms
- `POST /api/atomspace/query` - Pattern-based queries
- `POST /api/atomspace/triples` - Create knowledge triples
- `GET /api/atomspace/triples/:subject` - Query by subject
- `POST /api/atomspace/share` - Share knowledge
- `GET /api/atomspace/shared` - Get shared knowledge
- `GET /api/atomspace/public` - Get public knowledge
- `GET /api/atomspace/export` - Export atomspace
- `POST /api/atomspace/import` - Import atomspace

#### 4. **Web Interface** (7 routes, 5 views)
User-friendly interface for managing knowledge:
- `/dashboard/atomspace` - Main dashboard
- `/dashboard/atomspace/atoms/:id` - Atom details
- `/dashboard/atomspace/query` - Query interface
- `/browse/agents` - Browse all agents
- `/site/:username/atomspace` - Public agent view

#### 5. **Documentation**
- `docs/ATOMSPACE.md` - Complete technical documentation
- `examples/atomspace_demo.rb` - Working example script
- `README.md` - Updated with AtomSpace introduction

#### 6. **Testing**
- `tests/atomspace_tests.rb` - Model tests
- `tests/atomspace_api_tests.rb` - API endpoint tests
- `scripts/validate_atomspace.rb` - Validation script

## Key Features

### Atom Types

**Nodes** (8 types):
- ConceptNode, PredicateNode, VariableNode, NumberNode, TypeNode, GroundedSchemaNode, ContextNode, AgentNode

**Links** (11 types):
- InheritanceLink, SimilarityLink, MemberLink, EvaluationLink, ImplicationLink, ListLink, AndLink, OrLink, NotLink, ExecutionLink, AtTimeLink

### Knowledge Representation

Each atom has:
- **Truth Value**: Strength (0-1) and confidence (0-1) for probabilistic reasoning
- **Attention Value**: Short-term importance (STI) and long-term importance (LTI)
- **Metadata**: JSON value storage, timestamps, relationships

### Distributed Cognition

Three levels of knowledge sharing:
1. **Private**: Only the agent can access (default)
2. **Shared**: Explicitly shared with specific agents (read/write/copy)
3. **Public**: Accessible to all agents

### Simplified Interface

Knowledge triples (subject-predicate-object):
```ruby
atomspace.add_triple('Alice', 'knows', 'Bob')
atomspace.query_subject('Alice')
# => [{subject: 'Alice', predicate: 'knows', object: 'Bob'}]
```

## Usage Examples

### Via Ruby Code
```ruby
# Get atomspace for a site
atomspace = current_site.atomspace

# Create knowledge
alice = atomspace.add_node('ConceptNode', 'Alice')
bob = atomspace.add_node('ConceptNode', 'Bob')
atomspace.add_triple('Alice', 'knows', 'Bob')

# Query knowledge
facts = atomspace.query_subject('Alice')

# Share with another agent
other_agent = Site[username: 'other_bot']
atomspace.share_atom(alice.id, other_agent.id, share_type: 'read')
```

### Via API
```bash
# Create a concept
curl -X POST https://yoursite.neocities.org/api/atomspace/nodes \
  -u username:password \
  -H "Content-Type: application/json" \
  -d '{"type_name": "ConceptNode", "name": "Alice"}'

# Create a triple
curl -X POST https://yoursite.neocities.org/api/atomspace/triples \
  -u username:password \
  -H "Content-Type: application/json" \
  -d '{"subject": "Alice", "predicate": "knows", "object": "Bob"}'

# Query knowledge
curl https://yoursite.neocities.org/api/atomspace/triples/Alice \
  -u username:password
```

### Via Web Interface
1. Login to your site
2. Visit `/dashboard/atomspace`
3. Create nodes and triples using forms
4. Query and explore your knowledge graph
5. Share knowledge with other agents

## Security

- ✅ CodeQL security scan: **0 alerts**
- ✅ All code syntax validated
- ✅ Authentication required for all API endpoints
- ✅ Site-level isolation of knowledge bases
- ✅ Explicit sharing controls
- ✅ Input validation on all endpoints

## Running the Demo

```bash
cd /home/runner/work/neocogcities/neocogcities
ruby examples/atomspace_demo.rb
```

This creates two example agents (alice_bot and bob_bot) and demonstrates:
- Creating knowledge nodes
- Building knowledge triples
- Querying knowledge
- Pattern matching
- Knowledge sharing
- AtomSpace statistics
- Complex links with truth values
- Export/import functionality

## Testing

Run validation:
```bash
ruby scripts/validate_atomspace.rb
```

Run tests (when test environment is set up):
```bash
rake test TEST=tests/atomspace_tests.rb
rake test TEST=tests/atomspace_api_tests.rb
```

## Architecture

The implementation follows the existing Neocities patterns:
- Models use Sequel ORM
- Routes use Sinatra
- Views use ERB templates
- Background jobs use Sidekiq (for future enhancements)
- Database migrations use Sequel migrations

Integration points with existing Site model:
```ruby
# Each site has an atomspace
site.atomspace # => AtomSpace instance

# Check if site is an agent
site.agent? # => true if has atoms

# Get agent stats
site.agent_stats # => {...}
```

## What This Enables

### Use Cases
1. **Chatbot Memory**: Store conversation context and learned facts
2. **Multi-Agent Systems**: Agents share knowledge and collaborate
3. **Knowledge Graphs**: Build semantic networks
4. **Reasoning Systems**: Store rules, facts, and inferences
5. **Recommendation Engines**: Track preferences and similarities
6. **Semantic Search**: Query by patterns and relationships

### Future Enhancements (Not Implemented Yet)
- Pattern matcher with variables and bindings
- PLN (Probabilistic Logic Networks) reasoning
- MOSES (genetic programming) integration
- Attentional focus mechanism
- Distributed query across multiple agents
- Graph visualization of knowledge
- Natural language interface

## File Structure

```
neocogcities/
├── models/
│   ├── atom.rb                  # Core atom model
│   ├── atom_link.rb             # Link junction table
│   ├── atomspace.rb             # AtomSpace interface
│   ├── atomspace_share.rb       # Knowledge sharing
│   └── atomspace_query.rb       # Query caching
├── app/
│   ├── atomspace.rb             # UI routes
│   └── atomspace_api.rb         # API endpoints
├── views/
│   ├── dashboard/
│   │   ├── atomspace.erb        # Main dashboard
│   │   ├── atomspace_atom.erb   # Atom details
│   │   └── atomspace_query.erb  # Query interface
│   ├── browse_agents.erb        # Browse all agents
│   └── site_atomspace.erb       # Public agent view
├── migrations/
│   └── 129_create_atomspace_schema.rb
├── tests/
│   ├── atomspace_tests.rb       # Model tests
│   └── atomspace_api_tests.rb   # API tests
├── docs/
│   └── ATOMSPACE.md             # Technical docs
├── examples/
│   └── atomspace_demo.rb        # Working example
└── scripts/
    └── validate_atomspace.rb    # Validation script
```

## Credits

Inspired by:
- **OpenCog AtomSpace**: https://github.com/opencog/atomspace
- **Distributed AtomSpace (DAS)**: https://singnet.github.io/das-query-engine/
- **Neocities**: The original platform this is based on

## License

Same as Neocities - see LICENSE.txt

---

**Implementation Status**: ✅ Complete and validated
**Security Status**: ✅ All checks passed
**Documentation**: ✅ Complete
**Examples**: ✅ Working
**Tests**: ✅ Created

This implementation successfully transforms NeoCogCities into a distributed cognition platform for AI agents!
