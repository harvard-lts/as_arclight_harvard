
# as_arclight_custom_example

An ArchivesSpace plugin that demonstrates how to customize as_arclight mappings.

Explanation of the files in this plugin:

* config.yml - This file contains plugin configuration information. It is not
  required, but the following will ensure `as_arclight` is present at start up,
  and that the plugins are loaded in the correct order:
  ```
  depends_on_plugins:
      - as_arclight
  ```

* indexer/plugin_init.rb - In this file the plugin loads its custom mapping
  classes, and registers them with the Arclight mapper.

* indexer/custom_resource_mapper.rb - The custom mapping class. It must
  subclass Arclight::Mapper or one of its descendents. It defines a `map`
  method that includes the desired customizations. If it subclasses one of
  the existing mappers, it can call `super` to perform the default mapping,
  and then apply its customizations - as shown in the example.
