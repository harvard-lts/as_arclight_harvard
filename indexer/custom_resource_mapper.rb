require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'

class CustomResourceMapper < Arclight::ResourceMapper

  def map
    # Call super to include the default mapping from ResourceMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super

    # pump the numbers!
    map_field('total_component_count_is', [@json['_total_components'].to_i * 1000])
  end

end
