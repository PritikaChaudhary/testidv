class EmailsController < ApplicationController
  ActionController::Base.helpers
  include ActionView::Helpers::NumberHelper
  require 'date'




  def index
   # email = Email.new
    #email.name = "Sub Broker Login"
    #email.subject = "Your Sub Broker Login"
   # email.subject = "New FD Loan Submission"
    #email.content = "<p> Following are the fields that are submitted by the user: </p><br> submitted_fields"
   # email.fixed_variable = "submitted_fields"
   # email.save
    @emails = Email.all
  end

  def update_email
    email = Email.find(params[:id])
    email.content = params[:content]
    email.subject = params[:subject]
    email.save
    @emails = Email.all
    render partial: 'emails/emails'
  end
  
  
end
