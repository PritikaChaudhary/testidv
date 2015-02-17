class AdminController < ApplicationController

  def index
    @users = User.all
    authorize User
  end
  


 def new_user
   @user = User.new
   authorize @user
 end
 
 
 def edit_user
     @user = User.find(params[:id])
     authorize @user
 end 
 
 
 def create_user
    @user = User.new(params[:user])
    authorize @user
    
    @user.password_confirmation = @user.password
    
    @roles = Array.new
    if !params[:roles].blank?
      params[:roles].each do |item|
        @roles.push(Role.new(:name=>item[1]))
      end
    end
    @user.roles = @roles
    
    if @user.save :safe => true
     flash[:notice] = @user.email + " Created Successfully"
    else
     flash[:alert] = "Something went wrong! You may need a longer password. Please try again."
     redirect_to action: 'new_user'
     return
    end
    
    redirect_to action: 'index'

 end
 
 
 
 def update_user
    @user = User.find(params[:id])

    @roles = Array.new
    if !params[:roles].blank?
      params[:roles].each do |item|
        @roles.push(Role.new(:name=>item[1]))
      end
    end
    @user.roles = @roles
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
    end
    
    @user.attributes= params[:user].except(:roles)

    if @user.save :safe =>true, :validate => false

      flash[:notice] = @user.email + " Updated Successfully"
      redirect_to action: 'index'
      return
    else
      flash[:alert] = "Something went wrong! Try Again."
      render 'edit_user'
      return
    end
 end 

 
 def destroy_user

  @user = User.find(params[:id])
  authorize @user
  if @user.destroy
      flash[:notice] = @user.email + " Removed Successfully"
      redirect_to action: 'index'    
  else
      flash[:alert] = 'Something went wrong! Please try agian.'
      redirect_to action: 'index'    
  end   
 end
 
 
 
end




