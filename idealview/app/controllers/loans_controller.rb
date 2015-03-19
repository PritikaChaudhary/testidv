class LoansController < ApplicationController
  ActionController::Base.helpers
  require 'date'




  def index
    authorize Loan
    @loans = Infusionsoft.data_query('Contact',1000,0,{:ContactType=>'Borrower'},Loan.highlight_fields) 
    @loans.each_with_index do |loan, i|

      if loan['_LoanName'].blank?
        loan['_LoanName'] = 'Awesome Loan Name'
      end 

        dbLoan = Loan.find_by_id(loan['Id'])
        if dbLoan.blank?
          dbLoan = Loan.new()
          dbLoan.id = loan['Id']
          dbLoan.name=loan['_LoanName']
          dbLoan.info = loan
          dbLoan.save
        else
            dbLoan.name=loan['_LoanName']
            dbLoan.save
        end
        if dbLoan.archived
          @loans.delete_at(i)
        end
     end
     
    
  end
  
  
  
  def temp
    # @loans = Infusionsoft.data_query('Contact',1000,0,{:ContactType=>'Borrower'},Loan.highlight_fields) 
    @loans = Loan.all
    @output=Array.new
    @loans.each do |loan|
      loan.images.each do |temp|
        temp.delete
      end
      image_keys = loan.get_s3_images
      if !image_keys.blank?
        if image_keys.first.is_a?(String)
          @output<<image_keys
          image_keys.each do |key|
              check = Image.find_by_file_id(key)
              file_name = key.gsub(loan.id.to_s+'/', '')
              if !check.blank? && check.url.blank?
                dbImage = check
                dbImage.file_id = key_name
                dbImage.name = file_name
                dbImage.url = "https://s3-us-west-2.amazonaws.com/#{S3_BUCKET_NAME}/#{loan.id}/#{file_name}"
                dbImage.src = ''
                dbImage.data = ''
              
              else 
                  dbImage = Image.new(
                                :loan_id=>loan.id,
                                :file_id=>key, 
                                :name=>file_name, 
                                :url=>"https://s3-us-west-2.amazonaws.com/#{S3_BUCKET_NAME}/#{loan.id}/#{file_name}"
                                ) 
              end  
              dbImage.save           
          end
          
          

          
          
        end
      end
    end

    # @loans.each do |loan|
        # dbLoan = Loan.find_by_id(loan['Id'])
        # if dbLoan.blank?
          # dbLoan = Loan.new()
          # dbLoan.id = loan['Id']
          # dbLoan.save
        # end
        # dbLoan.images.each do |temp|
          # if temp.url.blank?
            # temp.delete
          # end
        # end
        # @images = dbLoan.get_images
#      
    # end 
    # temp = @loans.count 
 
  end
  
  
  
  
  
  
  def show
    loan_url = LoanUrl.find_by_url(params[:id])
    if loan_url
      @loan = loan_url.loan
      if loan_url.visits.blank?
        loan_url.visits = Array.new
      end
      loan_url.visits<<Time.now.getutc
      loan_url.save
      
    end
    
    if @loan.blank? && !current_user.blank?
      @loan = Loan.find_by_id(params[:id].to_i)
    end


    if @loan.blank?
      flash[:alert] ='You have either selected an invalid loan or you are not authorized to view this loan.'
      redirect_to '/'
      return
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
      @images = @loan.images
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
      @loan.name = contact['_LoanName']
      @images = @loan.images
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
   file_name = uploaded_io.original_filename
   
    File.open(Rails.root.join('public', 'temp', file_name), 'wb') do |file|
      contents = uploaded_io.read
      file.write(contents)
      
      
      # Make an object in your bucket for your upload
      key_name = loan.id.to_s+'/'+file_name
      
      obj = S3.put_object(
               acl: "public-read",
               bucket: S3_BUCKET_NAME,
               key: key_name,
               body: contents
               )
    
       #clear all featured image tags
        @check = false
        loan.images.each do |img|
              if img.featured 
              img.featured = false
              img.save()
             end
        end
        
        if obj.last_page?
            ext =  file_name.split('.').last.downcase 
            check = Image.find_by_name(file_name)
            if check && check.loan_id == loan.id
              image = check
            else
              image = Image.new(:loan_id=>loan._id, :file_id=>key_name, :name=>file_name, :url=>"https://s3-us-west-2.amazonaws.com/#{S3_BUCKET_NAME}/#{loan.id}/#{file_name}");
            end
            image.featured = true
            image.save()
         end   
      
    end
    redirect_to action: 'show', id: params[:id]
  end




  def upload_image
   
   loan=Loan.find_by_id(params[:id].to_i)
   files =  params[:files]
   output = Hash.new
   output['files']=Array.new
   
   files.each do |file_io|
     file_name=file_io.original_filename
     
     File.open(Rails.root.join('public', 'temp', file_io.original_filename), 'wb') do |file|
        
      contents = file_io.read
      # Make an object in your bucket for your upload
      key_name = loan.id.to_s+'/'+file_name
      obj = S3.put_object(
               acl: "public-read",
               bucket: S3_BUCKET_NAME,
               key: key_name,
               body: contents
               )
          
          if obj.last_page?
            ext =  file_name.split('.').last.downcase 
            check = Image.find_by_name(file_name)
            if check && check.loan_id == loan.id
              image = check
            else
              image = Image.new(:loan_id=>loan._id, :file_id=>key_name, :name=>file_name, :url=>"https://s3-us-west-2.amazonaws.com/#{S3_BUCKET_NAME}/#{loan.id}/#{file_name}");
            end
            image.featured = false
            image.save()
            output['files'].push({:name=>file_name, :success=>'Upload was successful!'})

          end    
       
     end 
   end
    render json: output
    return
  end






  def delete_image
    if params[:id]
      img = Image.find_by__id(params[:id])
        # begin
          # Infusionsoft.file_replace(img.file_id.to_i, '')
        # rescue Exception
        # end
      #remove from aws s3
      if !img.blank?
        S3.delete_object(
          bucket: S3_BUCKET_NAME,
          key: img.file_id.to_s,
        )
        
        img.delete
      end
    end
      
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
  
  
  def archive
    @loan = Loan.find_by_id(params[:id].to_i)
    @loan.archived = true
    @loan.save
    Infusionsoft.contact_add_to_group(@loan.id, 282) 
    redirect_to :action =>"index", :id=>@loan.id    
  end


end
