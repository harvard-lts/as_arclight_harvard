require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'

class CustomArchivalObjectMapper < Arclight::ArchivalObjectMapper

  def map
    # Call super to include the default mapping from ArchivalObjectMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    map_field('unitid_ssm', @json.fetch('component_id', ''))

  end

end
