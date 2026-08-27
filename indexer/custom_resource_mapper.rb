require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'

class CustomResourceMapper < Arclight::ResourceMapper
  # BEGIN cribbing from core

  # Hate this but to guarantee consistent behavior with former EAD process,
  # we need to run it through the same methods it's run through in core, and
  # they live in the backend rather than the indexer so they're not directly usable here
  def remove_smart_quotes(content)
    content.gsub(/\xE2\x80\x9C/, '"').gsub(/\xE2\x80\x9D/, '"').gsub(/\xE2\x80\x98/, "\'").gsub(/\xE2\x80\x99/, "\'")
  end

  def strip_p(content)
    content.gsub("<p>", "").gsub("</p>", "").gsub("<p/>", '')
  end

  # ANW-716: We may have content with a mix of loose '&' chars that need to be escaped, along with pre-escaped HTML entities
  # Example:
  # c                 => "This is the &lt; test & for the <title>Sanford &amp; Son</title>
  # escape_content(c) => "This is the &lt; test &amp; for the <title>Sanford &amp; Son</title>
  # we want to leave the pre-escaped entities alone, and escape the loose & chars
  def escape_content(content)
    # first, find any pre-escaped entities and "mark" them by replacing & with @@
    # so something like &lt; becomes @@lt;
    # and &#1234 becomes @@#1234

    content.gsub!(/&\w+;/) {|t| t.gsub('&', '@@')}
    content.gsub!(/&#\d{4}/) {|t| t.gsub('&', '@@')}
    content.gsub!(/&#\d{3}/) {|t| t.gsub('&', '@@')}

    # now we know that all & characters remaining are not part of some pre-escaped entity, and we can escape them safely
    content.gsub!('&', '&amp;')

    # 'unmark' our pre-escaped entities
    content.gsub!(/@@\w+;/) {|t| t.gsub('@@', '&')}
    content.gsub!(/@@#\d{4}/) {|t| t.gsub('@@', '&')}
    content.gsub!(/@@#\d{3}/) {|t| t.gsub('@@', '&')}

    return content
  end

  # ANW-669: Fix for attributes in mixed content causing errors when validating against the EAD schema.

  # If content looks like it contains a valid XML element with an attribute from the expected list,
  # then replace the attribute like " foo=" with " xlink:foo=".
  def add_xlink_prefix(content)
    %w{ actuate arcrole from href role show title to}.each do |xa|
      content.gsub!(/ #{xa}=/) {|match| " xlink:#{match.strip}"} if content =~ / #{xa}=/
    end
    content
  end

  XLINK_ELES = %w{ arc archref bibref extptr extptrloc extref extrefloc linkgrp ptr ptrloc ref refloc resource title }
  def sanitize_mixed_content(content)
    content = remove_smart_quotes(content)
    content.gsub!("<br>", "<br/>")
    content.gsub!("</br>", '')

    content = escape_content(content)
    content = strip_p(content)


    content = add_xlink_prefix(content) if XLINK_ELES.any? { |word| content =~ /<#{word}\s/ }
    return content
  end

  def fetch_tree_root(resource_uri)
    JSONModel::HTTP.get_json(resource_uri + '/tree/root', :published_only => true)
  end

  ## END of stuff cribbed from core

  def map
    # Call super to include the default mapping from ResourceMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    unitid = (0..3).map {|i| @json["id_#{i}"]}.compact.join('.')
    map_field('unitid_ssm', unitid )
    map_field('unitid_tesim', unitid)
    map_field('title_html_tesm', sanitize_mixed_content(@json["title"]))
    map_field('sponsor_tesm', sanitize_mixed_content(@json.fetch("finding_aid_sponsor", '')))
    # Containers - AFAICT containers are mapped into the EAD serially with top container
    #   first and subsequent containers following, and picked up by traject grabbing solely
    #   type and indicator in sequence
    containers = fetch_tree_root(@json['uri'])
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

    hollis_number = @json['notes'].find {|n| n['label'] == 'Alma ID'}.dig('subnotes', 0, 'content')
    map_field('hollis_number_ssi', hollis_number)
  end

end
