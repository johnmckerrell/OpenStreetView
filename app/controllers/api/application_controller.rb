require 'json'
class Api::ApplicationController < ApplicationController
  layout nil

  def render_multiformat
    # FIXME - Makes testing easier, make dev env only perhaps
    headers['content-type'] = 'text/plain'
    if @result.nil?
      render :nothing => true
    else
      puts "request.format=#{request.format}"
      respond_to do |format|
        puts "format=#{format}"
        format.json { render :json => @result }
        format.kml { render :template => 'api/kml' }
      end
    end
  end

  def render_json
    # FIXME - Makes testing easier, make dev env only perhaps
    headers['content-type'] = 'text/plain'
    if @result
      render :json => @result
    else
      render :nothing => true
    end
  end

  def login_required
    if ! authorized?
      render :text => 'Unauthorized', :status => 401
    end
  end

  def catch_errors
    begin
      yield
    rescue APIError => e
    #rescue Exception => e
      report_error e
    end
  end

  def report_error(e)
    @result = { :message => e.to_s }
    if e.is_a?(APIError)
      @result[:message] = e.message
      @result[:code] = e.code
    else
      #@result[:message] = "Server error"
      @result[:code] = 500
    end
    headers['content-type'] = 'text/plain'
    render :json => @result, :status => @result[:code]
  end

  def output_json
    yield
    if @result.nil
      render :nothing => true
    else
      headers['content-type'] = 'text/plain'
      render :json => @result
    end
  end
  #def output_json
    #render :json => @output
  #end

end
