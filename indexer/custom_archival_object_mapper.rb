require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'

class CustomArchivalObjectMapper < Arclight::ArchivalObjectMapper
  def fetch_tree_node(resource_uri, node_uri)
    JSONModel::HTTP.get_json(resource_uri + '/tree/node', node_uri: node_uri)
  end

  def map
    # Call super to include the default mapping from ArchivalObjectMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    map_field('unitid_ssm', @json.fetch('component_id', ''))
    resource_uri = resource['uri']
    node_uri = @json['uri']
    node = fetch_tree_node(resource_uri, node_uri)
    containers = node.fetch('containers', [])
    map_field('containers_ssim', containers.flat_map {|c|
                out = []
                if @json['top_container_type']
                  out << "#{@json['top_container_type']} #{@json['top_container_indicator']}"
                end
                if @json['type_2']
                  out << "#{@json['type_2']} #{@json['indicator_2']}"
                end
                if @json['type_3']
                  out << "#{@json['type_3']} #{@json['indicator_3']}"
                end
                out
              })
  end

end
