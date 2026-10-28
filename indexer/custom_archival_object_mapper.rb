require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'
require_relative 'digital_objects_mapping'

class CustomArchivalObjectMapper < Arclight::ArchivalObjectMapper
  include DigitalObjectsMapping

  def map
    # Call super to include the default mapping from ArchivalObjectMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super
    map_field('unitid_ssm', @json.fetch('component_id', ''))
    map_field('digital_objects_ssm', digital_objects(@json.fetch('instances', [])))

  end

end
