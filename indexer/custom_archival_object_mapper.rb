require_relative '../../as_arclight/indexer/lib/mappers/arclight_mapper'

class CustomArchivalObjectMapper < Arclight::ArchivalObjectMapper

  def map
    # Call super to include the default mapping from ArchivalObjectMapper
    # Alternatively, remove the call to super and implement a complete mapping
    super

    # if this AO has any IIIF manifests associated with it,
    # the last one processed is available in #manifest
    # be sure to test for its presence before using it
    if manifest
      map_field('alt_thumbnail_ssi', manifest.thumbnail)
    end
  end

end
