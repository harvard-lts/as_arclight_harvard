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

  ## END of stuff cribbed from core

  def map
    # Call super to include the default mapping from ResourceMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    unitid = (0..3).map {|i| @json["id_#{i}"]}.compact.join('.')
    if unitid
      map_field('unitid_ssm', unitid)
      map_field('unitid_tesm', unitid)
    end
    map_field('title_html_tesm', sanitize_mixed_content(@json["title"]))
    if @json.key? 'finding_aid_sponsor'
      map_field('sponsor_tesm', sanitize_mixed_content(@json["finding_aid_sponsor"]))
    end
  end

end
