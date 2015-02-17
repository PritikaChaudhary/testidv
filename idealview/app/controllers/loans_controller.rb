class LoansController < ApplicationController
  ActionController::Base.helpers
  require 'date'


  def index
    authorize Loan
    @loans = Infusionsoft.data_query('Contact',1000,0,{:ContactType=>'Borrower'},Loan.highlight_fields) 

  end
  
  def show
    @loan = Loan.find_by_url(params[:id].to_s)
    
    if @loan.blank?
      @loan = Loan.find_by_id(params[:id].to_i)
    end


    if current_user.blank? && (@loan.url !=params[:id].to_s)
      flash[:alert] ='You have either selected an invalid loan or you are not authorized to view this loan.'
      redirect_to '/'
    end

    
    dateField = ['_ExpectedCloseDate', '_AppraisalDate', 'Birthday', 'DateCreated', 'LastUpdated']

    if @loan.blank?
      begin
        contact = Infusionsoft.data_load('Contact', params[:id], Loan.all_fields)
      rescue Exception
        flash[:alert] ='You have either selected an invalid loan or you are not authorized to view this loan.'
        redirect_to '/'
        return;
      end
        
      if contact['_LoanName'].blank?
        contact['_LoanName'] = 'Your Awesome Loan Name Here'
      end 
      
      dateField.each do |field|
        temp = contact[field]
        if !temp.blank?
          contact[field]=temp.year.to_s+'-'+temp.month.to_s+'-'+temp.day.to_s
        end
      end

      @loan = Loan.new
      @loan.name=contact['_LoanName']
      @loan._id = contact['Id']
      @loan.info = contact
      @images = @loan.get_images
      @documents = @loan.get_docs
      @loan.save()
    
    else
      begin
        contact = Infusionsoft.data_load('Contact', @loan._id, Loan.all_fields)

      rescue Exception
        flash[:alert] ='You selected an invalid loan.'
        redirect_to '/'
        return;
      end
      
      dateField.each do |field|
        temp = contact[field]
       if !temp.blank?
          contact[field]=temp.year.to_s+'-'+temp.month.to_s+'-'+temp.day.to_s
        end
    end
      @loan.info =  contact 
      @images = @loan.get_images
      @documents = @loan.get_docs
      @loan.save()
    
    end
     # render plain: @loan.info
    # return     

      
  end
  
 
  def edit_field
    if policy(Loan).update?

      @temp = params
      @field = params[:field]
      @format_type = params[:format_type]
      
      @field_value = params[@field]
      if @format_type == 'fd_money'
        @field_value = @field_value.to_s.gsub(/[^\d\.]/, '')
      end
      if @format_type == 'fd_date'
       # @field_value = @field_value.strftime("%m/%d/%Y")
      end
  
     
  
      if params[:edit]=='true'
        #render text: "#{@temp}"
        render partial: 'mini_form', locals:
        {
          edit: true,
          contact_id: params[:contact_id],
          format_type:params[:format_type], 
          field_type: params[:field_type], 
          field_label: params[:field_label], 
          field_name:params[:field_name],
          field_value:@field_value,
          field_options:params[:field_options]
        } 
      else
        if !params.has_key?('cancel')
          Infusionsoft.contact_update(params[:contact_id], { @field => @field_value})
        else
          
          temp = Infusionsoft.data_load('Contact', params[:contact_id], [params[:field_name]])
          @field_value = temp[params[:field_name]]
          if @format_type == 'fd_money'
            @field_value = @field_value.to_s.gsub(/[^\d\.]/, '')
          end
           
        end
  
        render partial: 'mini_form', locals:
        {
          edit: false,
          contact_id: params[:contact_id],
          format_type:params[:format_type],
          field_type: params[:field_type], 
          field_label: params[:field_label], 
          field_name:params[:field_name],
          field_value:@field_value, 
          field_options:params[:field_options]
  
        } 
      end  
    end
  end
  
  def update_amount_owed
    @loan = Loan.find_by_id(params[:id].to_i)
     # render plain: @loan.info
     # return
    if params[:_FreeandClear0] == '0'
      render partial: 'mini_form', locals:
          {
            edit: false,
            contact_id:params[:id],
            format_type: 'fd_money',
            field_type: 'text_field_tag', 
            field_label: 'Amount Owed', 
            field_name: '_AmountOwed',
            field_value: @loan.info['_AmountOwed'],
            field_options: ''
          }
    else
      render partial: 'mini_form', locals:
          {
            edit: false,
            contact_id:params[:id],
            format_type: 'fd_money',
            field_type: 'text_field_tag', 
            field_label: 'Amount Owed', 
            field_name: '_AmountOwed',
            field_value: 0,
            field_options: ''
          }
    end
  end
   
  
  def edit_category
    loan = Loan.find_by_id(params[:id].to_i)
    loan.info["_LendingCategory"] = params[:_LendingCategory] 
    loanCat = Loan.category_type_fields[loan.info["_LendingCategory"]]
    loan.info[loanCat] = params[loanCat]

   if params[:edit]=='true' 

      render partial: 'loan_category', locals:{contact: loan, edit: true}
      
   else
       if !params.has_key?('cancel')
        Infusionsoft.contact_update(params[:id], { '_LendingCategory' => params[:_LendingCategory], loanCat=>params[loanCat]})
        loan.info['_LendingCategory']=params[:_LendingCategory]
        loan.info['loanCat']=params[loanCat]
        loan.save()
      else
        #temp = Infusionsoft.data_load('Contact', params[:contact_id], ['_LendingCategory', loanCat])
        loan.info["_LendingCategory"] = loan.category
        loan[loanCat] = loan.loan_type
      end
 
      
      render partial: 'loan_category', locals:{contact: loan, edit: false}
   end
    
  end
 
 
 
  def edit_loan_type
    
    types = Loan.category_type_fields
    loanCat = params[:_LendingCategory]
    loan_type_options = Loan.loan_type_options
    # render text: loan_type_options[loanCat]
    # return

    render partial: 'loan_type_form', locals:{category: types[loanCat], options: loan_type_options[loanCat], field_value: ''}
  end
  
  
  def images
    loan = Loan.find_by_id(params[:id].to_i)
    if !loan.blank?
      loan.get_images
      temp = loan.images
    render partial: 'thumbnails', locals:{images: temp, loan_id:loan._id}
    end

  end
  
  def image
    loan = Loan.find_by_id(params[:id].to_i)
    if !loan.blank?
      loan.images.each do |item|
        if item[:file_id].to_s==params[:image_id].to_s
           send_data Base64.decode64(item[:data]),
            :type => item[:src], :disposition => 'inline'
          return;
        end
      end
    end
  end


  #upload the main image for the loan
  def upload_main_image
   loan=Loan.find_by_id(params[:id].to_i)
   uploaded_io = params[:upload]
    File.open(Rails.root.join('public', 'temp', uploaded_io.original_filename), 'wb') do |file|
      contents = uploaded_io.read
      base64Contents = Base64.encode64(contents)
      file.write(contents)
       
       #check each image and see if it is already in infusionsoft
        @check = false
        loan.get_images.each do |img|
          fields = ['Id']
             if img.featured 
              img.featured = false
              img.save()
             end

          if uploaded_io.original_filename == img.name
            @check = img
            @check.featured = true
            @check.save()  
          end
        end
        
        if @check==false
          @isFile = Infusionsoft.file_upload(params[:id].to_i, uploaded_io.original_filename, base64Contents)
            ext =  uploaded_io.original_filename.split('.').last.downcase 
            image = Image.new(:loan_id=>loan._id, :file_id=>@isFile.to_i, :name=>uploaded_io.original_filename,:src=>"data:image/#{ext};base64",:data=>base64Contents);
            image.featured = true
            image.save()
         end   
      
    end
    redirect_to action: 'view', id: params[:id]
    #render plain: @isFile
    #  render nothing: true

  end

  def upload_image
   
   loan=Loan.find_by_id(params[:id].to_i)
   files =  params[:files]
   output = Hash.new
   output['files']=Array.new
   
   files.each do |file_io|
     File.open(Rails.root.join('public', 'temp', file_io.original_filename), 'wb') do |file|
        
      contents = file_io.read
      base64Contents = Base64.encode64(contents)
      file.write(contents)
         output['files'].push({:name=>file_io.original_filename, :success=>'Upload was successful!'})
          #check each image and see if it is already in infusionsoft
          @check = false
          loan.get_images.each do |img|
            fields = ['Id']
            if file_io.original_filename == img.name
              @check = img
            end
          end
          
          if @check==false
            @isFile = Infusionsoft.file_upload(params[:id].to_i, file_io.original_filename, base64Contents)
              ext =  file_io.original_filename.split('.').last.downcase 
              image = Image.new(:loan_id=>loan._id, :file_id=>@isFile.to_i, :name=>file_io.original_filename,:src=>"data:image/#{ext};base64",:data=>base64Contents);
              image.save()
          end    
       
     end 
   end
    render json: output
    return
  end

  def delete_image
    img = Image.find_by_file_id(params[:id].to_i)
      begin
        Infusionsoft.file_replace(img.file_id.to_i, '')
      rescue Exception
      end
    
    img.delete
    render plain: ''
  end



  def upload_doc
   loan=Loan.find_by_id(params[:id].to_i)
   files =  params[:files]
   output = Hash.new
   output['files']=Array.new
   
   files.each do |file_io|
     File.open(Rails.root.join('public', 'temp', file_io.original_filename), 'wb') do |file|
        
      contents = file_io.read
      base64Contents = Base64.encode64(contents)
      file.write(contents)
         output['files'].push({:name=>file_io.original_filename, :success=>'Upload was successful!'})
          #check each image and see if it is already in infusionsoft
          @check = false
          loan.get_docs.each do |img|
            fields = ['Id']
            if file_io.original_filename == img.name
              @check = img
            end
          end
          
          if @check==false
            @isFile = Infusionsoft.file_upload(params[:id].to_i, file_io.original_filename, base64Contents)
              ext =  file_io.original_filename.split('.').last.downcase 
              doc = Document.new(:loan_id=>loan._id, :file_id=>@isFile.to_i, :name=>file_io.original_filename, :category=>params[:category]);
              doc.save()
          end    
       
     end 
   end
    render json: output
    return    
  end


  def view_doc
    doc = Document.find_by_file_id(params[:id].to_i)
    begin
      contents = Infusionsoft.file_get(params[:id])
    rescue
        flash[:alert] ='The document you selected is not available.'
        redirect_to '/'
        return;
    end
    
    if doc.blank?
        flash[:alert] ='The document you selected is not available.'
        redirect_to '/'
        return;     
    end
    
    decodedContents = Base64.decode64(contents); 

    fileName = Rails.root.join('public', 'temp', doc[:name])
    File.open(fileName, 'wb') { |f| f.write(decodedContents) }
    send_file fileName
    return
  end


  def update
    @loan = @loan = Loan.find_by_id(params[:id].to_i)
    @loan.allowed_emails = params[:loan][:allowed_emails]
    @loan.save
    flash[:notice] = "Allowed Emails updated successfully"    
    redirect_to :action => "show", :id => params[:id]
    
  end



  def reset_url
    @loan = @loan = Loan.find_by_id(params[:id].to_i)
    @loan.url = Digest::MD5.hexdigest('funding'+@loan._id.to_s+Time.now.getutc.to_s)
    @loan.save
    host = request.host || "http://fundingdatabase.com"
    render plain: host+'/loans/'+@loan.url
  end
 
  
  def get_url
    @loan = @loan = Loan.find_by_id(params[:id].to_i)
    if @loan.url.blank?
      @loan.url =  Digest::MD5.hexdigest('funding'+@loan._id.to_s+Time.now.getutc.to_s)
      @loan.save
    end
    host = request.host || "http://fundingdatabase.com"
    render plain: host+'/loans/'+@loan.url
  end
 

  def nda_signed
    @loan = Loan.find_by_id(params[:id].to_i)
    if params[:name].blank? || params[:email].blank?
      flash[:alert] = "All fields are required"
      render 'show'
      return
    end
    
    if @loan.allowed_emails.include? params[:email]

      if @loan.ndas.blank?
        nda = Nda.new
        nda.loan_id = params[:id].to_i
        nda.name = params[:name]
        nda.email = params[:email]
        nda.date = Time.now
        nda.save
      else
        nda = Nda.find_by_email(params[:email])
        if nda.blank?
          nda = Nda.new
          nda.loan_id = params[:id].to_i
          nda.name = params[:name]
          nda.email = params[:email]
          nda.date = Time.now
          nda.save  
        end
  
      end 
      @loan.nda_signed = true
    else
      flash[:alert] = "You are not on the list of approved emails. If you would like access to this loan please send an email to administrator@fundingdatabase.com."
    end   
   
    render 'show' 
  end


end
