require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'
require_relative './mapper_common'
class CustomArchivalObjectMapper < Arclight::ArchivalObjectMapper
  include MapperCommon
  def map
    # Call super to include the default mapping from ArchivalObjectMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    map_field('unitid_ssm', @json.fetch('component_id', ''))
    map_field('title_html_tesm', sanitize_mixed_content(@json["title"]))

    nths = @json["title"].gsub(/\s*,\s*$/, '').strip
    unless @json["dates"].blank?
      nths << ", " << @json["dates"].first['expression'].strip
    end
    map_field('normalized_title_html_ssm', nths)

    extents =  @json.fetch('extents', []).map do |e|
      out = ""
      if e['number'] && e['extent_type']
        out << sanitize_mixed_content("#{e['number']} #{I18n.t('enumerations.extent_extent_type.'+e['extent_type'], :default => e['extent_type'])}")
      end
      if e['container_summary'] && !e['container_summary'].strip.blank?
        container_summary = e['container_summary']
        unless container_summary.match(/\A\(.*\)\z/)
          container_summary = "(#{container_summary})"
        end
        out << " " << container_summary
      end
      out.strip
    end
    map_field('extent_ssm', extents)
    map_field('extent_tesim', extents)

    resource_uri = resource['uri']

    containers = @json.fetch('instances', []).filter_map do |i|
      if i.has_key?("sub_container")

        sc = i['sub_container']
        tc = sc['top_container']['_resolved']
        out = [tc['display_string']]
        unless sc['type_2'].blank?
          out << "#{I18n.t('enumerations.container_type.' + sc['type_2'], default: sc['type_2'])} #{sc['indicator_2']}"
        end
        unless sc['type_3'].blank?
          out << "#{I18n.t('enumerations.container_type.' + sc['type_3'], default: sc['type_3'])} #{sc['indicator_3']}"

        end
        out
      end
    end

    map_field('containers_ssim', containers.flatten)

    has_digital_instance = walk(resource_uri, starting_point: @json['uri']) do |node|
      if node['has_digital_instance']
        break true
      end
    end
    map_field('has_online_content_ssim', has_digital_instance ? "true" : "false")
  rescue
    ARCLog.error("Failure while processing record: #{@json['uri']}")
    raise
  end

end
