module Dsc
  class Resource

    attr_accessor :resource_cim_class

    def initialize(mof_class, mof_path)
      @resource_mof_path   = mof_path
      @resource_cim_class  = mof_class
      @name                = nil
      @friendlyname                = nil
      @properties          = nil
      @filtered_properties = nil
      @module              = nil
    end

    def friendlyname
      @friendlyname ||= @resource_cim_class.qualifiers['Friendlyname'].value if @resource_cim_class.qualifiers['Friendlyname']

    end

    def name
      @ame ||= @resource_cim_class.name
    end

    def properties
      unless @properties
        @properties ||= @resource_cim_class.features.collect{|cim_feature| Dsc::Property.new(cim_feature) }
      end
      @properties
    end

    def filtered_properties
      unless @filtered_properties
        @filtered_properties = properties.select{|p| !p.dependable? && !p.is_ensure? }.sort_by { |p| [p.required? ? 0 : 1, p.name.downcase] }
      end
      @filtered_properties
    end

    def ensurable?
      properties.detect{|p|p.is_ensure?} ? true : false
    end

    def has_name?
      properties.detect{|p|p.is_name?} ? true : false
    end

    def dsc_module
      unless @dsc_module
        path_array = @resource_mof_path.split('/')
        revert_array = path_array.reverse
        downcased_array = revert_array.collect{|p| p.downcase}
        index = downcased_array.index('dscresources')
        @dsc_module = revert_array[index + 1 ] rescue binding.pry
      end
      @dsc_module
    end

  end
end