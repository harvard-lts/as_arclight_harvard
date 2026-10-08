require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'
require_relative './mapper_common'
require 'set'
class CustomResourceMapper < Arclight::ResourceMapper
  include MapperCommon
  # add top_container to resolves
  def self.resolves
    ['repository', 'linked_agents', 'subjects', 'top_container']
  end

  def map
    # Call super to include the default mapping from ResourceMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    unitid = (0..3).map {|i| @json["id_#{i}"]}.compact.join('.')
    map_field('unitid_ssm', unitid )
    map_field('unitid_tesim', unitid)
    map_field('title_html_tesm', sanitize_mixed_content(@json["title"]))

    nths = @json["title"].gsub(/\s*,\s*$/, '').strip
    unless @json["dates"].blank?
      nths << ", " << @json["dates"].first['expression'].strip
    end
    map_field('normalized_title_html_ssm', nths)

    extents = @json.fetch('extents', []).map do |e|
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

    map_field('sponsor_tesm', sanitize_mixed_content(@json.fetch("finding_aid_sponsor", '')))

    # Containers - AFAICT containers are mapped into the EAD serially with top container
    #   first and subsequent containers following, and picked up by traject grabbing solely
    #   type and indicator in sequence
    containers = @json.fetch('instances', []).filter_map do |i
      if i.has_key? "sub_container"

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

    hollis_number = @json['notes'].find {|n| Set['Alma ID', 'Aleph ID'].include? n['label'] }&.dig('subnotes', 0, 'content')
    map_field('hollis_number_ssi', hollis_number)

    has_digital_instance = walk(@json['uri']) do |node|
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
