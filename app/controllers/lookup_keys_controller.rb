class LookupKeysController < ApplicationController
  skip_before_filter :require_login, :only => :q
  skip_before_filter :require_ssl, :only => :q

  def index
    @lookup_key = LookupKey.all
  end

  def new
    @lookup_key = LookupKey.new
    2.times { @lookup_key.lookup_values.build }
  end

  def edit
    @lookup_key = LookupKey.find(params[:id])
  end

  def create
    @lookup_key = LookupKey.new(params[:lookup_key])

    if @lookup_key.save
      process_success
    else
      process_error
    end
  end

  def update
    @lookup_key = LookupKey.find(params[:id])

    if @lookup_key.update_attributes(params[:lookup_key])
      process_success
    else
      process_error
    end
  end

  def destroy
    @lookup_key = LookupKey.find(params[:id])
    if @lookup_key.destroy
      process_success
    else
      process_error
    end
  end

  # query action providing variable names - e.g. for extlookup
  def q
    key, order = params[:key], params[:order]
    invalid_request if key.nil? or order.nil? or not order.is_a?(Array)
    output = LookupKey.search(key, order)
    render :text => '404 Not Found', :status => 404 and return unless output
    respond_to do |format|
      format.html { render :text => output }
      format.yml { render :text => output.to_yaml }
    end
  end

end
