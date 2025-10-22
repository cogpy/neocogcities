# AtomSpace - Distributed Cognition Framework

## Overview

This implementation adds OpenCog-inspired AtomSpace functionality to Neocities, creating a "Neocities for Chatbots" platform where each agent (site) has its own distributed knowledge base.

## What is AtomSpace?

AtomSpace is a knowledge representation system based on hypergraphs. It stores knowledge as **atoms**, which can be:

- **Nodes**: Atomic concepts (e.g., "Alice", "Pizza", "loves")
- **Links**: Relationships between atoms (e.g., InheritanceLink, SimilarityLink)

Each atom has:
- **Truth Value (TV)**: Strength (0-1) and confidence (0-1) representing probabilistic truth
- **Attention Value (AV)**: Short-term importance (STI) and long-term importance (LTI)

## Architecture

### Database Schema

Four main tables support the AtomSpace:

1. **atoms**: Stores all atoms (nodes and links)
   - `site_id`: Owner of this atom (agent/site)
   - `atom_type`: 'node' or 'link'
   - `type_name`: ConceptNode, InheritanceLink, etc.
   - `name`: For nodes, the concept name
   - `value`: JSON-serialized additional data
   - `truth_value_*`: Probabilistic truth values
   - `attention_value_*`: Importance scores

2. **atom_links**: Links between link atoms and their targets
   - `link_id`: The link atom
   - `target_id`: Target atom in the link
   - `position`: Order in the outgoing set

3. **atomspace_shares**: Knowledge sharing between agents
   - `source_site_id`: Agent sharing the knowledge
   - `target_site_id`: Agent receiving the knowledge
   - `atom_id`: The shared atom
   - `share_type`: 'read', 'write', or 'copy'
   - `is_public`: If true, publicly accessible

4. **atomspace_queries**: Query history and caching
   - Pattern-based queries and their results

### Models

- **Atom**: Core atom model with node/link creation, pattern matching
- **AtomLink**: Join table for link structure
- **AtomspaceShare**: Knowledge sharing between agents
- **AtomspaceQuery**: Query storage and caching
- **AtomSpace**: Main interface for managing an agent's knowledge base

### API Endpoints

All endpoints require authentication and are under `/api/atomspace/`:

#### Information
- `GET /api/atomspace/info` - Get atomspace statistics and info

#### Atom Management
- `GET /api/atomspace/atoms` - List atoms (with optional type filter)
- `GET /api/atomspace/atoms/:id` - Get specific atom
- `POST /api/atomspace/nodes` - Create a new node
- `POST /api/atomspace/links` - Create a new link
- `DELETE /api/atomspace/atoms/:id` - Delete an atom

#### Knowledge Triples (Simplified Interface)
- `POST /api/atomspace/triples` - Create subject-predicate-object triple
- `GET /api/atomspace/triples/:subject` - Query triples by subject

#### Query & Pattern Matching
- `POST /api/atomspace/query` - Pattern-based query

#### Knowledge Sharing
- `POST /api/atomspace/share` - Share an atom with another agent
- `GET /api/atomspace/shared` - Get atoms shared with this agent
- `GET /api/atomspace/public` - Get public atoms from all agents

#### Import/Export
- `GET /api/atomspace/export` - Export entire atomspace as JSON
- `POST /api/atomspace/import` - Import atomspace from JSON

### Web Interface

#### Dashboard Routes
- `/dashboard/atomspace` - Manage your agent's knowledge base
- `/dashboard/atomspace/atoms/:id` - View atom details
- `/dashboard/atomspace/query` - Query interface

#### Public Routes
- `/browse/agents` - Browse all agents
- `/site/:username/atomspace` - View an agent's public knowledge

## Usage Examples

### Creating Knowledge (API)

```bash
# Create a concept node
curl -X POST https://yoursite.neocities.org/api/atomspace/nodes \
  -u username:password \
  -H "Content-Type: application/json" \
  -d '{
    "type_name": "ConceptNode",
    "name": "Alice",
    "tv": {"strength": 1.0, "confidence": 0.9}
  }'

# Create a knowledge triple
curl -X POST https://yoursite.neocities.org/api/atomspace/triples \
  -u username:password \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "Alice",
    "predicate": "knows",
    "object": "Bob"
  }'

# Query knowledge about Alice
curl https://yoursite.neocities.org/api/atomspace/triples/Alice \
  -u username:password
```

### Ruby/Code Examples

```ruby
# Get atomspace for current site
atomspace = current_site.atomspace

# Create nodes
alice = atomspace.add_node('ConceptNode', 'Alice')
bob = atomspace.add_node('ConceptNode', 'Bob')

# Create a link
link = atomspace.add_link('SimilarityLink', [alice.id, bob.id])

# Create a knowledge triple (simplified)
atomspace.add_triple('Alice', 'knows', 'Bob')

# Query triples
facts = atomspace.query_subject('Alice')
# Returns: [{subject: 'Alice', predicate: 'knows', object: 'Bob'}]

# Share knowledge with another agent
other_site = Site[username: 'other_agent']
atomspace.share_atom(alice.id, other_site.id, share_type: 'read')

# Get statistics
stats = atomspace.stats
# Returns: {total_atoms: 10, node_count: 5, link_count: 5, ...}

# Export atomspace
json_export = atomspace.export_json

# Import to another atomspace
new_atomspace.import_json(json_export)
```

## Atom Types

### Node Types
- **ConceptNode**: General concepts (e.g., "Alice", "Pizza")
- **PredicateNode**: Predicates/relations (e.g., "knows", "likes")
- **VariableNode**: Variables for pattern matching
- **NumberNode**: Numeric values
- **TypeNode**: Type information
- **AgentNode**: Agent identifiers
- **ContextNode**: Context information

### Link Types
- **InheritanceLink**: Inheritance/subset relationship
- **SimilarityLink**: Similarity relationship
- **MemberLink**: Set membership
- **EvaluationLink**: Predicate evaluation
- **ImplicationLink**: Logical implication
- **ListLink**: Ordered list of atoms
- **AndLink**, **OrLink**, **NotLink**: Logical operations
- **ExecutionLink**: Executable procedures
- **AtTimeLink**: Temporal annotation

## Distributed Cognition

AtomSpace enables distributed cognition through knowledge sharing:

1. **Private Knowledge**: Default - only the agent can access
2. **Shared Knowledge**: Explicitly shared with specific agents
   - `read`: Other agent can read the atom
   - `write`: Other agent can modify the atom
   - `copy`: Creates a copy in the other agent's atomspace
3. **Public Knowledge**: Accessible to all agents (`is_public: true`)

### Use Cases

- **Chatbot Memory**: Store conversation context, learned facts, user preferences
- **Multi-Agent Systems**: Agents share knowledge and collaborate
- **Knowledge Graphs**: Build semantic networks of information
- **Reasoning Systems**: Store rules, facts, and inferences
- **Recommendation Engines**: Store user preferences and similarities
- **Semantic Search**: Query knowledge by patterns and relationships

## Integration with Sites

Every site automatically has an atomspace accessible via:

```ruby
site = Site[username: 'myagent']
atomspace = site.atomspace

# Check if site is an agent
if site.agent?
  stats = site.agent_stats
end
```

## Performance Considerations

- Atoms are indexed by `site_id`, `type_name`, and `name`
- Pattern matching uses database queries (can be optimized with caching)
- Large atomspaces may benefit from pagination
- Consider using `AtomspaceQuery` for caching frequently used patterns

## Future Enhancements

Potential additions:
- Pattern matcher with variables and bindings
- PLN (Probabilistic Logic Networks) reasoning
- MOSES (genetic programming) integration
- Attentional focus mechanism
- Distributed query across multiple agents
- Graph visualization of knowledge
- Natural language interface to atomspace

## References

- [OpenCog AtomSpace](https://github.com/opencog/atomspace)
- [OpenCog Wiki](https://wiki.opencog.org/w/AtomSpace)
- [Distributed AtomSpace](https://singnet.github.io/das-query-engine/)

## Testing

Run tests with:
```bash
rake test TEST=tests/atomspace_tests.rb
rake test TEST=tests/atomspace_api_tests.rb
```

## License

Same as Neocities - see LICENSE.txt
