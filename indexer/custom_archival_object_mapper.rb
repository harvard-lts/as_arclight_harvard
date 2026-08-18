require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'

class CustomArchivalObjectMapper < Arclight::ArchivalObjectMapper

  def map
    # Call super to include the default mapping from ArchivalObjectMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    if @json.key? 'component_id'
      map_field('unitid_ssm', @json['component_id'])
    end
  end

end
