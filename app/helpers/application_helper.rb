# Methods added to this helper will be available to all templates in the application
module ApplicationHelper

  def contract model
    model.to_s
  end
  def graph(type,opts = {})
    Gchart.send(type, {:size => '400x150', :bg => "EDF3EF", :format => "image_tag"}.merge(opts))
  end

  def show_habtm associations
    render :partial => 'common/show_habtm', :collection => associations, :as => :association
  end

  def edit_habtm klass, association
    render :partial => 'common/edit_habtm', :locals =>{ :klass => klass, :associations => association.all.sort.delete_if{|e| e == klass}}
  end

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(image_tag("false.png", :title => "remove"), "remove_fields(this)")
  end

  # Creates a link to a javascript function that creates field entries for the association on the web page
  # +name+       : String containing links's text
  # +f+          : FormBuiler object
  # +association : The field are created to allow entry into this association
  # +partial+    : String containing an optional partial into which we render
  def link_to_add_fields(name, f, association, partial = nil)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render((partial.nil? ? association.to_s.singularize + "_fields" : partial), :f => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"))
  end

  def toggle_div div
    update_page do |page|
      page << "if ($('#{div}').visible()) {"
      page[div].hide
      page << "} else {"
      page[div].visual_effect :BlindDown, :duration => 0.1
      page << "}"
    end
  end

  def link_to_remove_puppetclass klass
    link_to_function image_tag("delete.png") do |page|
      page["selected_puppetclass_#{klass.id}"].remove
      #TODO if the class is already selected, removing it will not add it to the avail class list
      page << "if ($('puppetclass_#{klass.id}')) {"
      page["puppetclass_#{klass.id}"].show
      page << "}"
    end
  end

  def link_to_add_puppetclass klass, type
    # link to remote is faster than inline js when having many classes
    link_to_remote "&nbsp;&nbsp;&nbsp;" + image_tag("add.png"),
      :url => assign_puppetclass_path(klass, :type => type),
      :position => {:after => {:success => "selected_classes" }}
  end

  def check_all_links(form_name)
    link_to_function("Check all", "checkAll('#{form_name}', true)") +
    " | " +
    link_to_function("Uncheck all", "checkAll('#{form_name}', false)")
  end

  def searchtab title, search, options
    opts = {:action => params[:action], :tab_name => title, :search => search}
    selected_class = options[:selected] ? "selectedtab" : ""
    content_tag(:li) do
      link_to opts, :class => selected_class do
        h(title) + (options[:no_close_button] ? "": (link_to "x", opts.merge(:remove_me => true), :class => "#{selected_class} close"))
      end
    end
  end

  def toggle_searchbar
    update_page do |page|
      page['search'].toggle
      page['tabs'].toggle
    end
  end

  # a simple helper to load the google JS only on pages which requires it
  def gcharts_script
    content_for :head do
      "<script src=#{request.protocol}www.google.com/jsapi></script>"
    end
  end

  def fact_name_select
    param = params[:search]["#{@via}fact_name_id_eq"] if params[:search]
    return param.to_i unless param.empty?
    return @fact_name_id if @fact_name_id
  end

  # Return true if user is authorized for controller/action, otherwise false
  # +controller+ : String or symbol for the controller
  # +action+     : String or symbol for the action
  def authorized_for(controller, action)
    User.current.allowed_to?({:controller => controller, :action => action}) rescue false
  end

  # Display a link if user is authorized, otherwise a string
  # +name+    : String to be displayed
  # +options+ : Hash containing
  #             :enable_link  : Boolean indicating whether the link is to be displayed
  #             :controlller  : String or Symbol representing the controller
  #             :auth_action  : String or Symbol representing the action to be used for authorization checks
  # +html_options+ : Hash containing html options for the link or span
  def link_to_if_authorized(name, options = {}, html_options = {})
    enable_link = options.has_key?(:enable_link) ? options.delete(:enable_link) : true
    auth_action = options.delete :auth_action
    if enable_link
      link_to_if authorized_for(options[:controller] || params[:controller], auth_action || options[:action]), name, options, html_options
    else
      content_tag(:span, name, {:class => "entry"}.merge(html_options))
    end
  end

  # Display a link if user is authorized, otherwise nothing
  # +name+    : String to be displayed
  # +options+ : Hash containing
  #             :controlller  : String or Symbol representing the controller
  #             :auth_action  : String or Symbol representing the action to be used for authorization checks
  # +html_options+ : Hash containing html options for the link or span
  def display_link_if_authorized(name, options = {}, html_options = nil)
    auth_action = options.delete :auth_action
    link_to(name, options, html_options) if authorized_for(options[:controller] || params[:controller], auth_action || options[:action])
  end

  def authorized_edit_habtm klass, association
    return edit_habtm(klass, association) if authorized_for params[:controller], params[:action]
    show_habtm klass.send(association.name.pluralize.downcase)
  end

  # renders a style=display based on an attribute properties
  def display? attribute
    "style=#{display(attribute)}"
  end

  def display attribute
    "display:#{attribute ? 'none' : 'inline'};"
  end

  # return our current model instance type based on the current controller
  # i.e. HostsController would return "host"
  def type
    controller_name.singularize
  end

  def checked_icon condition
    return image_tag "toggle_check.png" if condition
  end

end
