class Emailer < ActionMailer::Base

  ActionMailer::Base.default_url_options[:host] = "http://blunt.lt.local:3000/" 

  ActionMailer::Base.default_url_options[:port] = 3000
  
  def new_request(id)
    begin 
    	@request = Request.find(id)
    	emails = []
    	User.where(admin: true).each do |u|
    	  emails << u.email
    	end
      employee = User.where(login: @request.name).first
      if employee != nil
        emails << employee.email
      end

      if @request.customer != nil
        cust = User.where(login: @request.customer).first
        if cust != nil
          emails << cust.email
        end
      end 

     	mail :to => emails, :from => "SynBioAdmin@lanzatech.onmicrosoft.com", :subject => "New Request: '#{@request.title}'"
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      logger.debug "#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.drop(1).map{|s| "\t#{s}"}
    end
  end

  def edit_request(id)
    begin
      @request = Request.find(id)
      employee = User.where(login: @request.name).first
      if @request.check_for_edits_email == false
        return
      end

      emails = []
      User.where(login: @request.get_users).each do |u|
        emails << u.email
      end

      if @request.customer != nil
        cust = User.where(login: @request.customer).first
        if cust != nil
          emails << cust.email
        end
      end 

      edit_type_assignment = @request.check_version_attribute_change("Assignment")
      edit_type_status = @request.check_version_attribute_change("Status")
      
      if edit_type_assignment.length > 0 
        mail :to => emails, :from => "SynBioAdmin@lanzatech.onmicrosoft.com", :subject => "Request: '#{@request.title}' has been assigned", template_name: 'edit_assignment'
        return 
      end

      if edit_type_status.length > 0
        mail :to => emails, :from => "SynBioAdmin@lanzatech.onmicrosoft.com", :subject => "Request: '#{@request.title}' has changed status", template_name: 'edit_status'
        return
      end

      mail :to => emails, :from => "SynBioAdmin@lanzatech.onmicrosoft.com", :subject => "Request: '#{@request.title}' has been edited"
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      logger.debug "#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.drop(1).map{|s| "\t#{s}"}
    end
  end 

  def new_model_request()
    emails = []
    User.where(admin: true).each do |u|
      emails << u.email
    end
    mail :to => emails, :from => "SynBioAdmin@lanzatech.onmicrosoft.com", :subject => "New Model Request"
  end
end
