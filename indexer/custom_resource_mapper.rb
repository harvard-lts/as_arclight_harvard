require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'

class CustomResourceMapper < Arclight::ResourceMapper
  # Hate this but to guarantee consistent behavior with former EAD process,
  # we need to run it through the same method
  @serializer = EADSerializer.new

  def map
    # Call super to include the default mapping from ResourceMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super

    map_field('unitid_ssm', (0..3).map {|i| @json["id_#{i}"]}.compact.join('.'))
    map_field('title_html_tesm', sanitize_mixed_content(@json["title"]))

  end

  def sanitize_mixed_content(content)
    content = @serializer.remove_smart_quotes(content)
    content.gsub!("<br>", "<br/>")
    content.gsub!("</br>", '')

    content = @serializer.escape_content(content)
    content = @serializer.strip_p(content)

    xlink_eles = %w{ arc archref bibref extptr extptrloc extref extrefloc linkgrp ptr ptrloc ref refloc resource title }
    content = @serializer.add_xlink_prefix(content) if xlink_eles.any? { |word| content =~ /<#{word}\s/ }
  end
end
