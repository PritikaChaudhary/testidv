class LoanUrlMailer < ActionMailer::Base
  add_template_helper(FdCustomHelper)
  default from: "deals@fundingdatabase.com"
  
  def email_link(loan_url)
    @loan_url = loan_url
    @loan = @loan_url.loan
    emails = [loan_url.email]
    mail(to: emails, subject: 'New Deal For You To Review')

  end



end