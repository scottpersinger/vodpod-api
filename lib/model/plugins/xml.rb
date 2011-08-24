module Sequel
  module Plugins
    module Xml
      module InstanceMethods

        # Returns an XML node for this model.
        def to_xml
          node = LibXML::XML::Node.new(self.class.serialized_name)
          final_serialize_attrs.each do |attr|
            attr_node = LibXML::XML::Node.new(attr)
            node << attr_node
            
            value = send(attr)
            
            case value
            when Sequel::Plugins::Serialize::InstanceMethods
              # Let the model know it is being included.
              value.being_included = true
              # Serialize and store.
              attr_node << value.to_xml
            
            when Hash
              value.each do |k,v|
                attr_node << (key_node = LibXML::XML::Node.new(k.to_s))
                key_node << v.to_s
              end
            
            when Array
              single_attr = attr.to_s.singularize
              value.each do |elem|
                if Sequel::Plugins::Serialize::InstanceMethods === elem
                  # Let the model know it is being included.
                  elem.being_included = true
                end

                # Convert to XML
                elem_xml = elem.to_xml
                if elem_xml.text?
                  # If the element XML is a text node, we need to wrap it in
                  # a suitable element node.
                  single_node = LibXML::XML::Node.new(single_attr) 
                  attr_node << single_node
                  single_node << elem_xml
                else
                  # Otherwise, add the node directly to the list.
                  attr_node << elem_xml
                end
              end
            else
              # Add the value to the attribute
              attr_node << value.to_xml
            end
          end

          node
        end
      end
    end
  end
end
