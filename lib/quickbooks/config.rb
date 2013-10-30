module Quickbooks::Config

  API_ROOT = File.join(File.dirname(__FILE__), '..', '..').freeze
  XML_SCHEMA_PATH = File.join(API_ROOT, 'xml_schema').freeze   
  RUBY_SCHEMA_PATH = File.join(API_ROOT, 'ruby_schema').freeze 

private

  def dtd_file
    "#{XML_SCHEMA_PATH}/qbxmlops120.xml" 
  end

  def schema_namespace
    Quickbooks::QBXML
  end

  def container_class
    Quickbooks::QBXML::QBXML
  end

# introspection
  
  def cached_classes
    schema_namespace.constants.map { |const| schema_namespace.const_get(const) }
  end

end
