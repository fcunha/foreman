class ReportsController < ApplicationController
  skip_before_filter :require_login,             :only => :create
  skip_before_filter :require_ssl,               :only => :create
  skip_before_filter :authorize,                 :only => :create
  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :set_admin_user, :only => :create

  # avoids storing the report data in the log files
  filter_parameter_logging :report

  def index
    @interesting = (params[:search] and params[:search][:interesting] and params[:search][:interesting] == "true")
    search_cmd  = "Report"
    for condition in Report::METRIC
      search_cmd += ".with('#{condition.to_s}', #{params[condition]})" if params.has_key? condition
    end
    search_cmd += ".search(params[:search])"
    # set defaults search order - cant use default scope due to bug in AR
    # http://github.com/binarylogic/searchlogic/issues#issue/17
    params[:search] ||=  {}
    params[:search][:order] ||= "descend_by_created_at"

    @search  = eval search_cmd
    @reports = @search.paginate :page => params[:page]
  end

  def show
    @report = Report.find(params[:id])
    @offset = @report.reported_at - @report.created_at
  end

  def create
    respond_to do |format|
      format.yml {
        if Report.import params.delete("report")
          render :text => "Imported report", :status => 200 and return
        else
          render :text => "Failed to import report", :status => 500
        end
      }
    end
  rescue => e
    render :text => e.to_s, :status => 500
  end

  def destroy
    @report = Report.find(params[:id])
    if @report.destroy
      notice "Successfully destroyed report."
    else
      error @report.errors.full_messages.join("<br/>")
    end
    redirect_to reports_url
  end
end
