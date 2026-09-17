require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'
require_relative './mapper_common'
require 'set'
class CustomResourceMapper < Arclight::ResourceMapper
  include MapperCommon
  def map
    # Call super to include the default mapping from ResourceMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    unitid = (0..3).map {|i| @json["id_#{i}"]}.compact.join('.')
    map_field('unitid_ssm', unitid )
    map_field('unitid_tesim', unitid)
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

    map_field('sponsor_tesm', sanitize_mixed_content(@json.fetch("finding_aid_sponsor", '')))
    # Containers - AFAICT containers are mapped into the EAD serially with top container
    #   first and subsequent containers following, and picked up by traject grabbing solely
    #   type and indicator in sequence
    containers = fetch_tree_root(@json['uri']).fetch('containers', [])
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

    hollis_number = @json['notes'].find {|n| Set['Alma ID', 'Hollis ID'].include? n['label'] }&.dig('subnotes', 0, 'content')
    map_field('hollis_number_ssi', hollis_number)
  end

end
