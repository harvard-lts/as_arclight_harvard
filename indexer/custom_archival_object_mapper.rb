require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'
require_relative './mapper_common'
class CustomArchivalObjectMapper < Arclight::ArchivalObjectMapper
  include MapperCommon
  def fetch_tree_node(resource_uri, node_uri)
    JSONModel::HTTP.get_json(resource_uri + '/tree/node', node_uri: node_uri)
  end

  def map
    # Call super to include the default mapping from ArchivalObjectMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    map_field('unitid_ssm', @json.fetch('component_id', ''))
    map_field('title_html_tesm', sanitize_mixed_content(@json["title"]))

    nths = @json["title"].gsub(/\s*,\s*$/, '').strip
    unless @json["dates"].empty?
      nths << ", " << @json["dates"].first['expression'].strip
    end
    map_field('normalized_title_html_ssm', nths)

    map_field('extents_ssim', @json.fetch('extents', []).map do |e|
      out = ""
      if e['number'] && e['extent_type']
        out << sanitize_mixed_content("#{e['number']} #{I18n.t('enumerations.extent_extent_type.'+e['extent_type'], :default => e['extent_type'])}")
      end
      if e['container_summary'] && !e['container_summary'].strip.empty?
        container_summary = e['container_summary']
        unless container_summary.match(/\A\(.*\)\z/)
          container_summary = "(#{container_summary})"
        end
        out << " " << container_summary
      end
      out.strip end
    )

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


    has_digital_instance = walk(resource_uri, starting_point=@json['uri']) do |node|
      if node['has_digital_instance']
        break true
      end
    end
    map_field('has_online_content_ssm', has_digital_instance)
  end

end
