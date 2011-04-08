class HostgroupsController < ApplicationController
  include Foreman::Controller::HostDetails

  filter_parameter_logging :root_pass
  before_filter :find_hostgroup, :only => [:show, :edit, :update, :destroy, :clone]

  def index
    respond_to do |format|
      format.html do
        @search     = Hostgroup.search params[:search]
        @hostgroups = @search.paginate :page => params[:page]
      end
      format.json { render :json => Hostgroup.all }
    end
  end

  def new
    @hostgroup = Hostgroup.new
  end

  # Clone the hostgroup
  def clone
    new = @hostgroup.clone
    load_vars_for_ajax
    new.puppetclasses = @hostgroup.puppetclasses
    # Clone any parameters as well
    @hostgroup.group_parameters.each{|param| new.group_parameters << param.clone}
    flash[:error_customisation] = {:header_message => "Clone Hostgroup", :class => "flash notice", :id => nil,
      :message => "The following fields will need reviewing:" }
    new.valid?
    new.name = ""
    @hostgroup = new
    render :action => :new
  end

  def show
    respond_to do |format|
      format.json { render :json => @hostgroup }
    end
  end

  def create
    @hostgroup = Hostgroup.new(params[:hostgroup])
    if @hostgroup.save
      process_success
    else
      load_vars_for_ajax
      process_error
    end
  end

  def edit
    load_vars_for_ajax
  end

  def update
    if @hostgroup.update_attributes(params[:hostgroup])
      process_success
    else
      load_vars_for_ajax
      process_error
    end
  end

  def destroy
    if @hostgroup.destroy
      process_success
    else
      load_vars_for_ajax
      process_error
    end
  end

  private

  def find_hostgroup
    @hostgroup = Hostgroup.find(params[:id])
  end

  def load_vars_for_ajax
    return unless @hostgroup
    @architecture    = @hostgroup.architecture
    @operatingsystem = @hostgroup.operatingsystem
  end

end
