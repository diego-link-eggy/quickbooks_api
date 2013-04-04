class Quickbooks::API
  include Quickbooks::Logger
  include Quickbooks::Config
  include Quickbooks::Support::Inflection

  attr_reader :dtd_parser, :qbxml_parser
  private_class_method :new
  @@instance = nil

  def initialize
    @classes_loaded = false
    @dtd_parser = Quickbooks::DtdParser.new
    @qbxml_parser = Quickbooks::QbxmlParser.new
    @@instance = self
  end

  def self.instance
    @@instance || new
  end

  # user friendly api decorators. Not used anywhere else.
  # 
  def container
    load_qb_classes_if_needed!
    container_class
  end

  def qbxml_classes
    load_qb_classes_if_needed!
    cached_classes
  end

  # api introspection
  #
  def find(class_name)
    load_qb_classes_if_needed!
    cached_classes.find { |c| underscore(c) == class_name.to_s }
  end

  def grep(pattern)
    load_qb_classes_if_needed!
    cached_classes.select { |c| underscore(c).match(/#{pattern}/) }
  end

  # QBXML 2 RUBY

  def qbxml_to_obj(qbxml)
    load_qb_classes_if_needed!
    qbxml_parser.parse(qbxml)
  end

  def qbxml_to_hash(qbxml, include_container = false)
    load_qb_classes_if_needed!
    if include_container
      qbxml_to_obj(qbxml).attributes
    else
      qbxml_to_obj(qbxml).inner_attributes
    end
  end

  # RUBY 2 QBXML

  def hash_to_obj(data)
    load_qb_classes_if_needed!
    key, value = data.detect { |name, value| name != 'xml_attributes' && name != :xml_attributes }
    key_path = container_class.template(true).path_to_nested_key(key.to_s)
    raise(RuntimeError, "#{key} class not found in api template") unless key_path

    wrapped_data = Hash.nest(key_path, value)
    container_class.new(wrapped_data)
  end

  def hash_to_qbxml(data)
    load_qb_classes_if_needed!
    hash_to_obj(data).to_qbxml
  end

private

  def load_qb_classes_if_needed!
    unless @classes_loaded
      puts "Loading QBXML classes ..."
      @classes_loaded = true

      rebuild_schema_cache(false)
      load_full_container_template
      container_class
      puts "... Done"
    end
  end

  # rebuilds schema cache in memory - very slow
  def rebuild_schema_cache(force = false)
    puts "\tCaching schema from DTD file ..."
    dtd_parser.parse_file(dtd_file) if (cached_classes.empty? || force)
  end

  # load the recursive container class template into memory (significantly
  # speeds up wrapping of partial data hashes) - fast enough
  def load_full_container_template(use_disk_cache = false)
    puts "\tCaching container template ..."
      container_class.template(true)
  end

end
