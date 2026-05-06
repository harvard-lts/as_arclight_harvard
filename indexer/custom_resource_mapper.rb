require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'

class CustomResourceMapper < Arclight::ResourceMapper

  def map
    # optional
    super

    # pump the numbers!
    map_field('total_component_count_is', [@json['_total_components'].to_i * 1000])
  end

end
