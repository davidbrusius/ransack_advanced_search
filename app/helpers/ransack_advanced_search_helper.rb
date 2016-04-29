module RansackAdvancedSearchHelper
  def setup_search_form(builder, search_object)
    fields = builder.grouping_fields builder.object.new_grouping,
      object_name: 'new_object_name', child_index: "new_grouping" do |f|
      render('ransack_advanced_search/grouping_fields', f: f)
    end
    content_for :ransack_setup, %Q{
      var search = new Search({grouping: "#{escape_javascript(fields)}"});
      search.fieldsType = #{get_fields_data_type(search_object).to_json.html_safe}
      search.convertFieldType = function (fieldType) {
        var fieldTypeToHtmlType = {
          'default': 'text',
          'integer': 'number',
          'date' : 'date',
          'datetime' : 'date'
        }
        return (fieldTypeToHtmlType[fieldType] || fieldTypeToHtmlType['default']);
      }
      search.changeValueInputsType = function(element, fieldName) {
        fieldType = search.fieldsType[fieldName];
        conditionValueInputs = $(element).parents('.ransack-condition-field').find('.ransack-attribute-value');
        conditionValueInputs.attr('type', search.convertFieldType(fieldType));
      }
      $(document).on("click", "button.add_fields", function() {
        search.add_fields(this, $(this).data('fieldType'), $(this).data('content'));
        if($(this).hasClass('ransack-add-attribute')) {
          fieldName = $(this).parents('.ransack-condition-field').find('select.ransack-attribute-select').find('option:selected')[0].value;
          search.changeValueInputsType(this, fieldName)
        }
        return false;
      });
      $(document).on('change', 'select.ransack-attribute-select', function(e) {
        fieldName = $(this).find('option:selected')[0].value;
        search.changeValueInputsType(this, fieldName)
      });
      $(document).on("click", "i.remove_fields", function() {
        search.remove_fields(this);
        return false;
      });
      $(document).on("click", "button.nest_fields", function() {
        search.nest_fields(this, $(this).data('fieldType'));
        return false;
      });
    }.html_safe
  end

  def get_fields_data_type(search)
    bases = [''] + search.klass.ransackable_associations
    fields_type = Hash.new
    bases.each do |model|
      model_name = model.present? ? "#{model}_" : ""
      search.context.traverse(model).columns_hash.each do |field, attributes|
        fields_type["#{model_name}#{field}"] = attributes.type
      end
    end
    fields_type
  end

  def button_to_remove_fields
    content_tag :i, nil, class: 'remove_fields glyphicon glyphicon-remove text-danger'
  end

  def button_to_add_fields(name, f, type, custom_class='')
    new_object = f.object.send "build_#{type}"
    fields = f.send("#{type}_fields", new_object, child_index: "new_#{type}") do |builder|
      render('ransack_advanced_search/' + type.to_s + "_fields", f: builder)
    end
    content_tag :button, name, :class => custom_class + ' add_fields btn btn-default btn-sm', :type => 'button', 'data-field-type' => type, 'data-content' => "#{fields}"
  end

  def button_to_nest_fields(name, type)
    content_tag :button, name, :class => 'nest_fields', 'data-field-type' => type
  end
end
